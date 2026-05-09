const repo = require('./parcel.repository');

async function getMyParcels(ownerId) {
  return repo.findAllByOwner(ownerId);
}

async function getParcelById(id, ownerId) {
  const parcel = await repo.findByIdAndOwner(id, ownerId);
  if (!parcel) throw Object.assign(new Error('Parcel not found'), { statusCode: 404 });
  return parcel;
}

async function registerParcel(ownerId, body) {
  const { name, location, areaAcres, soilType, phLevel,
          nitrogen, phosphorus, potassium, irrigation, coordinates } = body;

  if (coordinates && coordinates.length < 3) {
    throw Object.assign(
      new Error('At least 3 GPS coordinates are required to define a parcel boundary'),
      { statusCode: 400 },
    );
  }

  return repo.create({
    ownerId, name, location, areaAcres, soilType, phLevel,
    nitrogen, phosphorus, potassium, irrigation,
    coordinates: coordinates || [],
  });
}

async function updateParcel(id, ownerId, body) {
  const parcel = await repo.update(id, ownerId, body);
  if (!parcel) throw Object.assign(new Error('Parcel not found'), { statusCode: 404 });
  return parcel;
}

async function deleteParcel(id, ownerId) {
  const result = await repo.softDelete(id, ownerId);
  if (!result) throw Object.assign(new Error('Parcel not found'), { statusCode: 404 });
}

async function addCropHistory(parcelId, ownerId, body) {
  // Verify ownership
  await getParcelById(parcelId, ownerId);
  return repo.addCropHistory({ parcelId, ...body });
}

module.exports = {
  getMyParcels,
  getParcelById,
  registerParcel,
  updateParcel,
  deleteParcel,
  addCropHistory,
};
