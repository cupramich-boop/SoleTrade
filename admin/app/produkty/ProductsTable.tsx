import Link from 'next/link';

type Product = {
  id: string;
  title: string;
  price: number;
  status: string;
  is_featured: boolean;
  created_at: string;
  profiles: { username: string } | { username: string }[] | null;
  product_images: { image_url: string; is_main: boolean }[];
};

function sellerName(profiles: Product['profiles']) {
  if (!profiles) return '—';
  return Array.isArray(profiles) ? (profiles[0]?.username ?? '—') : profiles.username;
}

function coverImage(images: Product['product_images']) {
  if (images.length === 0) return null;
  return images.find((i) => i.is_main)?.image_url ?? images[0].image_url;
}

const STATUS_LABELS: Record<string, string> = {
  pending: 'Oczekuje',
  active: 'Aktywna',
  sold: 'Sprzedana',
  rejected: 'Odrzucona',
};

const STATUS_COLORS: Record<string, string> = {
  pending: 'bg-amber-100 text-amber-700',
  active: 'bg-green-100 text-green-700',
  sold: 'bg-gray-200 text-gray-600',
  rejected: 'bg-red-100 text-red-700',
};

export function ProductsTable({ products }: { products: Product[] }) {
  if (products.length === 0) {
    return (
      <div className="rounded-2xl border border-primary-light bg-white p-8 text-center text-gray-400">
        Brak produktów.
      </div>
    );
  }

  return (
    <div className="overflow-hidden rounded-2xl border border-primary-light bg-white">
      <table className="w-full text-sm">
        <thead className="bg-primary-light/40 text-left text-gray-600">
          <tr>
            <th className="px-4 py-3">Zdjęcie</th>
            <th className="px-4 py-3">Tytuł</th>
            <th className="px-4 py-3">Sprzedawca</th>
            <th className="px-4 py-3">Cena</th>
            <th className="px-4 py-3">Status</th>
            <th className="px-4 py-3">Akcje</th>
          </tr>
        </thead>
        <tbody>
          {products.map((product) => {
            const cover = coverImage(product.product_images);
            return (
              <tr key={product.id} className="border-t border-primary-light">
                <td className="px-4 py-3">
                  {cover ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img
                      src={cover}
                      alt=""
                      className="h-12 w-12 rounded-lg object-cover"
                    />
                  ) : (
                    <div className="h-12 w-12 rounded-lg bg-primary-light" />
                  )}
                </td>
                <td className="px-4 py-3 font-medium">{product.title}</td>
                <td className="px-4 py-3 text-gray-500">{sellerName(product.profiles)}</td>
                <td className="px-4 py-3">{product.price} zł</td>
                <td className="px-4 py-3">
                  <span
                    className={`rounded-full px-2.5 py-1 text-xs font-semibold ${STATUS_COLORS[product.status] ?? ''}`}
                  >
                    {STATUS_LABELS[product.status] ?? product.status}
                  </span>
                  {product.is_featured && (
                    <span className="ml-1.5 rounded-full bg-primary/10 px-2.5 py-1 text-xs font-semibold text-primary">
                      Polecane
                    </span>
                  )}
                </td>
                <td className="px-4 py-3">
                  <Link
                    href={`/produkty/${product.id}`}
                    className="rounded-lg bg-primary px-3 py-1.5 text-xs font-semibold text-white"
                  >
                    Edytuj
                  </Link>
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}
