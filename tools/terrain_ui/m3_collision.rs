// M3DT collision reader for version 1 files with a model-space collision mesh.
// The public M3DT.bt template documents CPOS, CNML and CINX. The framing and
// version fields were checked against the installed client's assets.

fn m3_collision(data: &[u8]) -> Result<Vec<Face>> {
    let mut cursor = data;
    let mut collision = None;
    let mut mesh_seen = false;
    let mut transform = None;
    while !cursor.is_empty() {
        let tag = slice(cursor, 0, 4)?;
        let size = u32at(cursor, 4)? as usize;
        let version = u32at(cursor, 8)?;
        let payload = slice(cursor, 16, size)?;
        match tag {
            b"M3DT" => ensure!(
                cursor.len() == data.len() && size == 88 && version == 1,
                "unsupported M3DT header"
            ),
            b"MES3" => {
                ensure!(!mesh_seen, "multiple M3DT render meshes");
                mesh_seen = true;
            }
            b"M3SI" | b"M3ST" | b"M3VS" => (),
            b"M3CL" => {
                ensure!(version == 0 && u32at(cursor, 12)? == 0, "unsupported M3DT collision version");
                ensure!(collision.replace(payload).is_none(), "duplicate M3DT collision mesh");
            }
            b"M3XF" => {
                ensure!(transform.is_none() && size == 64 && version == 1, "unsupported M3DT transform layout");
                let mut matrix = [0.0; 16];
                for (index, value) in matrix.iter_mut().enumerate() {
                    *value = f32at(payload, 4 * index)?;
                }
                transform = Some(matrix);
            }
            _ => return Err(anyhow::anyhow!("unsupported M3DT section {:?}", String::from_utf8_lossy(tag))),
        }
        cursor = &cursor[16 + size..];
    }
    ensure!(mesh_seen, "M3DT render mesh unavailable");
    let transform = transform.context("M3DT transform unavailable")?;
    // M3CL is optional. Render sections do not provide navigation collision.
    let Some(mut mesh) = collision else { return Ok(Vec::new()); };
    for (index, value) in transform.iter().enumerate() {
        let expected = if index % 5 == 0 { 1.0 } else { 0.0 };
        ensure!((value - expected).abs() < 1e-5,
            "non-identity M3DT transform requires a verified collision-space conversion");
    }
    let mut vertices = None;
    let mut normals = None;
    let mut indices = None;
    while !mesh.is_empty() {
        let tag = slice(mesh, 0, 4)?;
        let size = u32at(mesh, 4)? as usize;
        let data = slice(mesh, 8, size)?;
        let field = match tag {
            b"CPOS" => &mut vertices,
            b"CNML" => &mut normals,
            b"CINX" => &mut indices,
            _ => return Err(anyhow::anyhow!("unsupported M3DT collision section {:?}", String::from_utf8_lossy(tag))),
        };
        ensure!(field.replace(data).is_none(), "duplicate M3DT collision field");
        mesh = &mesh[8 + size..];
    }
    let vertices = vertices.context("M3DT collision positions unavailable")?;
    let indices = indices.context("M3DT collision indices unavailable")?;
    let normals = normals.context("M3DT collision normals unavailable")?;
    ensure!(indices.len() % 6 == 0 && normals.len() == indices.len() * 2, "invalid M3DT collision counts");
    faces(vertices, indices, None, false)
}

#[cfg(test)]
mod m3_tests {
    use super::*;

    fn chunk(out: &mut Vec<u8>, tag: &[u8; 4], version: Option<u32>, data: &[u8]) {
        out.extend(tag);
        out.extend((data.len() as u32).to_le_bytes());
        if let Some(version) = version {
            out.extend(version.to_le_bytes());
            out.extend(0u32.to_le_bytes());
        }
        out.extend(data);
    }

    fn model(third_index: Option<u16>, translation: f32) -> Vec<u8> {
        let mut mesh = Vec::new();
        let vertices: Vec<u8> = [0.0f32, 0.0, 2.0, 4.0, 0.0, 2.0, 0.0, 3.0, 2.0]
            .into_iter().flat_map(f32::to_le_bytes).collect();
        if let Some(third_index) = third_index {
            let indices: Vec<u8> = [0u16, 1, third_index].into_iter().flat_map(u16::to_le_bytes).collect();
            chunk(&mut mesh, b"CPOS", None, &vertices);
            chunk(&mut mesh, b"CNML", None, &[0; 12]);
            chunk(&mut mesh, b"CINX", None, &indices);
        }
        let transform: Vec<u8> = (0..16).flat_map(|index| {
            let value = if index % 5 == 0 { 1.0 } else if index == 12 { translation } else { 0.0 };
            value.to_le_bytes()
        }).collect();
        let mut data = Vec::new();
        chunk(&mut data, b"M3DT", Some(1), &[0; 88]);
        chunk(&mut data, b"MES3", Some(3), b"M3CL in render data");
        if third_index.is_some() {
            chunk(&mut data, b"M3CL", Some(0), &mesh);
        }
        chunk(&mut data, b"M3XF", Some(1), &transform);
        data
    }

    #[test]
    fn m3_reads_collision_indices_in_model_space() {
        let faces = m3_collision(&model(Some(2), 0.0)).unwrap();
        assert_eq!(faces, vec![[[0.0, 0.0, 2.0], [4.0, 0.0, 2.0], [0.0, 3.0, 2.0]]]);
    }

    #[test]
    fn m3_rejects_invalid_or_unverified_collision() {
        assert!(m3_collision(&model(Some(3), 0.0)).is_err());
        assert!(m3_collision(&model(Some(2), 1.0)).is_err());
        let mut truncated = model(Some(2), 0.0);
        truncated.pop();
        assert!(m3_collision(&truncated).is_err());
    }

    #[test]
    fn m3_render_only_model_has_no_collision() {
        let mut data = model(None, 1.0);
        assert!(m3_collision(&data).unwrap().is_empty());
        chunk(&mut data, b"NEXT", Some(0), &[]);
        assert!(m3_collision(&data).is_err());
    }
}
