#[cfg(test)]
mod texture_tests {
    use super::*;

    fn chunk(tag: &[u8; 4], payload: &[u8]) -> Vec<u8> {
        let mut data = Vec::new();
        data.extend(tag.iter().rev());
        data.extend((payload.len() as u32).to_le_bytes());
        data.extend(payload);
        data
    }

    fn texture_tile(base_flags: u32) -> Vec<u8> {
        let layer: Vec<u8> = [0u32, base_flags, 0, 0, 1, 256, 0, 0]
            .into_iter().flat_map(u32::to_le_bytes).collect();
        let cell = [chunk(b"MCLY", &layer), chunk(b"MCAL", &[192; 4096])].concat();
        let mut tile = chunk(b"MDID", &[0, 0, 0, 0, 42, 0, 0, 0]);
        tile.extend(chunk(b"MCNK", &cell));
        for _ in 1..256 {
            tile.extend(chunk(b"MCNK", &[]));
        }
        tile
    }

    #[test]
    fn untextured_base_keeps_the_overlay_and_its_opacity() {
        let mut tile = Tile::new();
        assert_eq!(textures(&texture_tile(0), &mut tile, true).unwrap(), 1);
        let layers = &tile.textures[0]["layers"];
        assert_eq!(layers[0]["texture"], 0);
        assert_eq!(layers[1]["texture"], 42);
        assert_eq!(layers[1]["alpha"].as_array().unwrap().len(), 4096);
        assert_eq!(layers[1]["alpha"][4095], 192);
        assert!(textures(&texture_tile(1), &mut Tile::new(), true).is_err());
    }
}
