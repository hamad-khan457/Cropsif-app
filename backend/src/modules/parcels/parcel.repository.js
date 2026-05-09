const { query } = require('../../config/database');

async function findAllByOwner(ownerId) {
  const { rows } = await query(
    `SELECT id, name, location, area_acres, soil_type, ph_level,
            nitrogen, phosphorus, potassium, irrigation,
            coordinates, active_crop, ndvi_score, is_active, created_at
     FROM parcels WHERE owner_id = $1 AND is_active = TRUE
     ORDER BY created_at DESC`,
    [ownerId],
  );
  return rows;
}

async function findByIdAndOwner(id, ownerId) {
  const { rows } = await query(
    `SELECT p.*,
            COALESCE(
              json_agg(ch ORDER BY ch.year DESC, ch.created_at DESC)
              FILTER (WHERE ch.id IS NOT NULL), '[]'
            ) AS crop_history
     FROM parcels p
     LEFT JOIN crop_history ch ON ch.parcel_id = p.id
     WHERE p.id = $1 AND p.owner_id = $2
     GROUP BY p.id`,
    [id, ownerId],
  );
  return rows[0] || null;
}

async function create({ ownerId, name, location, areaAcres, soilType, phLevel,
                        nitrogen, phosphorus, potassium, irrigation, coordinates }) {
  const { rows } = await query(
    `INSERT INTO parcels
       (owner_id, name, location, area_acres, soil_type, ph_level,
        nitrogen, phosphorus, potassium, irrigation, coordinates)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
     RETURNING *`,
    [ownerId, name, location, areaAcres, soilType, phLevel,
     nitrogen, phosphorus, potassium, irrigation,
     JSON.stringify(coordinates)],
  );
  return rows[0];
}

async function update(id, ownerId, fields) {
  const allowed = ['name','location','area_acres','soil_type','ph_level',
                   'nitrogen','phosphorus','potassium','irrigation',
                   'coordinates','active_crop'];
  const sets = [];
  const vals = [];
  let i = 1;
  for (const [k, v] of Object.entries(fields)) {
    if (!allowed.includes(k)) continue;
    sets.push(`${k} = $${i++}`);
    vals.push(k === 'coordinates' ? JSON.stringify(v) : v);
  }
  if (!sets.length) throw Object.assign(new Error('No valid fields to update'), { statusCode: 400 });
  sets.push(`updated_at = NOW()`);
  vals.push(id, ownerId);

  const { rows } = await query(
    `UPDATE parcels SET ${sets.join(', ')}
     WHERE id = $${i++} AND owner_id = $${i}
     RETURNING *`,
    vals,
  );
  return rows[0] || null;
}

async function softDelete(id, ownerId) {
  const { rows } = await query(
    `UPDATE parcels SET is_active = FALSE, updated_at = NOW()
     WHERE id = $1 AND owner_id = $2 RETURNING id`,
    [id, ownerId],
  );
  return rows[0] || null;
}

async function addCropHistory({ parcelId, cropName, season, year, yieldMds, notes }) {
  const { rows } = await query(
    `INSERT INTO crop_history (parcel_id, crop_name, season, year, yield_mds, notes)
     VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
    [parcelId, cropName, season, year, yieldMds, notes],
  );
  return rows[0];
}

module.exports = {
  findAllByOwner,
  findByIdAndOwner,
  create,
  update,
  softDelete,
  addCropHistory,
};
