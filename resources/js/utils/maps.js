export function googleMapsUrl({ destination = '', destinationAddress = '', latitude = null, longitude = null } = {}) {
  const hasCoords =
    latitude !== null &&
    latitude !== undefined &&
    latitude !== '' &&
    longitude !== null &&
    longitude !== undefined &&
    longitude !== '' &&
    !Number.isNaN(Number(latitude)) &&
    !Number.isNaN(Number(longitude));

  if (hasCoords) {
    return `https://www.google.com/maps/dir/?api=1&destination=${encodeURIComponent(`${Number(latitude)},${Number(longitude)}`)}`;
  }

  const query = String(destinationAddress || destination || '').trim();
  if (!query) return '';
  return `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(query)}`;
}

export function wazeUrl({ destination = '', destinationAddress = '', latitude = null, longitude = null } = {}) {
  const hasCoords =
    latitude !== null &&
    latitude !== undefined &&
    latitude !== '' &&
    longitude !== null &&
    longitude !== undefined &&
    longitude !== '' &&
    !Number.isNaN(Number(latitude)) &&
    !Number.isNaN(Number(longitude));

  if (hasCoords) {
    return `https://waze.com/ul?ll=${encodeURIComponent(`${Number(latitude)},${Number(longitude)}`)}&navigate=yes`;
  }

  const query = String(destinationAddress || destination || '').trim();
  if (!query) return '';
  return `https://waze.com/ul?q=${encodeURIComponent(query)}&navigate=yes`;
}

export function hasCoordinates(latitude, longitude) {
  return (
    latitude !== null &&
    latitude !== undefined &&
    latitude !== '' &&
    longitude !== null &&
    longitude !== undefined &&
    longitude !== '' &&
    !Number.isNaN(Number(latitude)) &&
    !Number.isNaN(Number(longitude))
  );
}

export function formatCoordinates(latitude, longitude) {
  if (!hasCoordinates(latitude, longitude)) return '';
  return `${Number(latitude).toFixed(5)}, ${Number(longitude).toFixed(5)}`;
}
