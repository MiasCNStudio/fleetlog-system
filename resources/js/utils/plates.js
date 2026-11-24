export const SV_PLATE_TYPES = [
  { code: 'P', label: 'P · Particular', tone: 'standard' },
  { code: 'CD', label: 'CD · Cuerpo Diplomático', tone: 'diplomatic' },
  { code: 'MI', label: 'MI · Misión Internacional', tone: 'mission' },
  { code: 'N', label: 'N · Nacional (Estado)', tone: 'national' },
  { code: 'CC', label: 'CC · Cuerpo Consular', tone: 'diplomatic' },
  { code: 'A', label: 'A · Alquiler (Taxi)', tone: 'standard' },
  { code: 'C', label: 'C · Comercial / Carga', tone: 'standard' },
  { code: 'M', label: 'M · Motocicleta', tone: 'standard' },
  { code: 'AB', label: 'AB · Autobús', tone: 'standard' },
  { code: 'MB', label: 'MB · Microbús', tone: 'standard' },
];

const SORTED_PREFIXES = [...SV_PLATE_TYPES]
  .map((t) => t.code)
  .sort((a, b) => b.length - a.length);

export function parseSalvadorPlate(licensePlate, explicitType = null, explicitNumber = null) {
  let type = explicitType ? String(explicitType).toUpperCase().trim() : '';
  let num = explicitNumber
    ? String(explicitNumber).toUpperCase().replace(/[^A-Z0-9]/g, '')
    : '';

  if (!type || !num) {
    const raw = String(licensePlate || '').toUpperCase().replace(/[^A-Z0-9]/g, '');
    for (const prefix of SORTED_PREFIXES) {
      if (raw.startsWith(prefix)) {
        const rest = raw.slice(prefix.length);
        if (rest.length >= 3 && /^[A-Z0-9]+$/.test(rest) && /\d/.test(rest)) {
          type = prefix;
          num = rest;
          break;
        }
      }
    }
  }

  if (!type || !num) {
    return {
      isSalvador: false,
      raw: String(licensePlate || '—'),
      type: '',
      left: '',
      right: '',
      tone: 'standard',
    };
  }

  const right = num.length > 3 ? num.slice(-3) : num;
  const left = num.length > 3 ? num.slice(0, -3) : '';
  const meta = SV_PLATE_TYPES.find((t) => t.code === type);

  return {
    isSalvador: true,
    raw: `${type}${num}`,
    type,
    number: num,
    left,
    right,
    tone: meta?.tone || 'standard',
  };
}
