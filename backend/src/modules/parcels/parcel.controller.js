const service = require('./parcel.service');
const { success } = require('../../utils/response.utils');

async function list(req, res, next) {
  try {
    const parcels = await service.getMyParcels(req.user.sub);
    return success(res, { parcels }, 'Parcels fetched');
  } catch (err) { next(err); }
}

async function getOne(req, res, next) {
  try {
    const parcel = await service.getParcelById(req.params.id, req.user.sub);
    return success(res, { parcel });
  } catch (err) { next(err); }
}

async function create(req, res, next) {
  try {
    const parcel = await service.registerParcel(req.user.sub, req.body);
    return success(res, { parcel }, 'Parcel registered successfully', 201);
  } catch (err) { next(err); }
}

async function update(req, res, next) {
  try {
    const parcel = await service.updateParcel(req.params.id, req.user.sub, req.body);
    return success(res, { parcel }, 'Parcel updated');
  } catch (err) { next(err); }
}

async function remove(req, res, next) {
  try {
    await service.deleteParcel(req.params.id, req.user.sub);
    return success(res, {}, 'Parcel removed');
  } catch (err) { next(err); }
}

async function addHistory(req, res, next) {
  try {
    const record = await service.addCropHistory(req.params.id, req.user.sub, req.body);
    return success(res, { record }, 'Crop history added', 201);
  } catch (err) { next(err); }
}

module.exports = { list, getOne, create, update, remove, addHistory };
