export const PRODUCT_SIZES = ['35-38', '39-42', '43-46', '47-50', 'Uniwersalny'];

export const PRODUCT_MATERIALS = [
  'Bawełna',
  'Poliester',
  'Wełna',
  'Nylon',
  'Elastan',
  'Bambus',
  'Mieszanka',
  'Inny',
];

export const PRODUCT_CONDITION_DAYS = [0, 1, 2, 3, 4, 5, 6, 7, 14, 30, 60, 90];

export const PRODUCT_STATUSES = ['pending', 'active', 'sold', 'rejected'] as const;

export function conditionDaysLabel(days: number): string {
  if (days === 0) return 'Nowe (nieużywane)';
  if (days === 1) return '1 dzień';
  if (days < 7) return `${days} dni`;
  if (days < 14) return '1 tydzień';
  if (days < 30) return `${Math.round(days / 7)} tygodnie`;
  if (days < 60) return '1 miesiąc';
  return `${Math.round(days / 30)} miesiące`;
}
