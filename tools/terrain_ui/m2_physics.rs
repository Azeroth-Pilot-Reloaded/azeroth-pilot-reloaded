// M2 navigation uses the MD20 bounding mesh. PHYS settings and articulated
// bone simulation are separate from that static collision mesh.
fn verify_m2_physics(data: &[u8], bone_count: usize) -> Result<()> {
    let chunks = Chunks::parse(data)?;
    let version = chunks.need(b"PHYS")?;
    let kind = chunks.need(b"PHYT")?;
    ensure!(version == [4, 0] && kind.len() == 4, "unsupported PHYS header");
    if chunks.0.iter().map(|(tag, _)| *tag).eq([*b"PHYS", *b"PHYT", *b"PHYV"]) {
        let values = chunks.0[2].1;
        ensure!(u32at(kind, 0)? == 2 && values.len() == 24, "unsupported PHYV settings");
        for offset in (0..24).step_by(4) {
            f32at(values, offset)?;
        }
        return Ok(());
    }
    ensure!(u32at(kind, 0)? == 3, "unsupported PHYT type");
    let mut tags = BTreeSet::new();
    for (tag, _) in &chunks.0 {
        ensure!(matches!(tag, b"PHYS" | b"PHYT" | b"CAPS" | b"PLYT" | b"SHP2" | b"BDY4" |
            b"SHOJ" | b"WLJ2" | b"REVJ" | b"JOIN") && tags.insert(tag),
            "unknown or duplicate PHYS section {:?}", String::from_utf8_lossy(tag));
    }
    let bodies = records(chunks.need(b"BDY4")?, 48)?;
    let body_count = bodies.len();
    let shapes = records(chunks.need(b"SHP2")?, 32)?;
    let capsules = chunks.get(b"CAPS").unwrap_or_default();
    let capsule_count = records(capsules, 28)?.len();
    let polytope_count = chunks.get(b"PLYT").map(|payload| u32at(payload, 0)).transpose()?.unwrap_or(0) as usize;
    for shape in shapes.clone() {
        let index = u16at(shape, 2)? as usize;
        ensure!(match u16at(shape, 0)? {
            1 => index < capsule_count,
            3 => index < polytope_count,
            _ => false,
        }, "unsupported PHYS shape reference");
    }
    let mut dynamic = false;
    for body in bodies {
        let body_kind = u16at(body, 0)?;
        let bone = u16at(body, 2)? as usize;
        let first = u16at(body, 16)? as usize;
        let count = u32at(body, 20)? as usize;
        // A kinematic anchor can constrain animated bones without owning a shape.
        ensure!(body_kind <= 1 && bone < bone_count && first <= shapes.len() && count <= shapes.len() - first
            && (body_kind == 0 || count > 0),
            "invalid PHYS bone body");
        dynamic |= body_kind == 1;
    }
    let mut linked = BTreeSet::new();
    for joint in records(chunks.need(b"JOIN")?, 16)? {
        let a = u32at(joint, 0)? as usize;
        let b = u32at(joint, 4)? as usize;
        ensure!(a != b && a < body_count && b < body_count, "invalid PHYS joint reference");
        linked.extend([a, b]);
    }
    ensure!(dynamic && linked.len() == body_count, "PHYS does not describe articulated animation");
    Ok(())
}

#[cfg(test)]
mod m2_physics_tests {
    use super::*;

    fn chunk(tag: &[u8; 4], data: &[u8]) -> Vec<u8> {
        let mut bytes = Vec::new();
        bytes.extend(tag.iter().rev());
        bytes.extend((data.len() as u32).to_le_bytes());
        bytes.extend(data);
        bytes
    }

    #[test]
    fn parameter_only_physics_has_no_static_collision() {
        let mut model = vec![0; 304];
        model[..8].copy_from_slice(b"MD20\x10\x01\x00\x00");
        let wrapped = [chunk(b"12DM", &model), chunk(b"DIFP", &321u32.to_le_bytes())].concat();
        let physics = [chunk(b"PHYS", &[4, 0]), chunk(b"PHYT", &2u32.to_le_bytes()), chunk(b"PHYV", &[0; 24])].concat();
        assert!(m2(&wrapped, |id| {
            assert_eq!(id, 321);
            Ok(physics.clone().into())
        }).unwrap().is_empty());
        let unknown = [physics, chunk(b"SHP2", &[0; 32])].concat();
        assert!(m2(&wrapped, |_| Ok(unknown.clone().into())).is_err());
        assert!(m2(&wrapped, |_| Err(anyhow::anyhow!("file unavailable"))).is_err());
    }

    #[test]
    fn articulated_physics_can_have_a_shapeless_kinematic_anchor() {
        let mut bodies = [0; 96];
        bodies[48] = 1;   // Dynamic body.
        bodies[50] = 1;   // Second bone.
        bodies[68] = 1;   // One shape.
        let mut shape = [0; 32];
        shape[0] = 1;     // Capsule.
        let mut joint = [0; 16];
        joint[4] = 1;    // Connect body zero to body one.
        let physics = [chunk(b"PHYS", &[4, 0]), chunk(b"PHYT", &3u32.to_le_bytes()),
            chunk(b"CAPS", &[0; 28]), chunk(b"SHP2", &shape), chunk(b"BDY4", &bodies)].concat();
        assert!(verify_m2_physics(&[physics.as_slice(), &chunk(b"JOIN", &joint)].concat(), 2).is_ok());
        assert!(verify_m2_physics(&[physics.as_slice(), &chunk(b"JOIN", &joint)].concat(), 1).is_err());
        assert!(verify_m2_physics(&physics, 2).is_err());
    }
}
