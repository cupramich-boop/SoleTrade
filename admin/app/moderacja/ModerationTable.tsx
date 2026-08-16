'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';

type Product = {
  id: string;
  title: string;
  price: number;
  size: string;
  material: string;
  condition_days: number;
  created_at: string;
  profiles: { username: string } | { username: string }[] | null;
};

function sellerName(profiles: Product['profiles']) {
  if (!profiles) return '—';
  return Array.isArray(profiles) ? profiles[0]?.username ?? '—' : profiles.username;
}

export function ModerationTable({ products }: { products: Product[] }) {
  const router = useRouter();
  const [pendingId, setPendingId] = useState<string | null>(null);

  async function updateStatus(id: string, status: 'active' | 'rejected') {
    setPendingId(id);
    await fetch(`/api/products/${id}/status`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ status }),
    });
    setPendingId(null);
    router.refresh();
  }

  if (products.length === 0) {
    return (
      <div className="rounded-2xl border border-primary-light bg-white p-8 text-center text-gray-400">
        Brak ofert oczekujących na moderację.
      </div>
    );
  }

  return (
    <div className="overflow-hidden rounded-2xl border border-primary-light bg-white">
      <table className="w-full text-sm">
        <thead className="bg-primary-light/40 text-left text-gray-600">
          <tr>
            <th className="px-4 py-3">Tytuł</th>
            <th className="px-4 py-3">Sprzedawca</th>
            <th className="px-4 py-3">Cena</th>
            <th className="px-4 py-3">Rozmiar / materiał</th>
            <th className="px-4 py-3">Akcje</th>
          </tr>
        </thead>
        <tbody>
          {products.map((product) => (
            <tr key={product.id} className="border-t border-primary-light">
              <td className="px-4 py-3 font-medium">{product.title}</td>
              <td className="px-4 py-3 text-gray-500">{sellerName(product.profiles)}</td>
              <td className="px-4 py-3">{product.price} zł</td>
              <td className="px-4 py-3 text-gray-500">
                {product.size} · {product.material}
              </td>
              <td className="px-4 py-3">
                <div className="flex gap-2">
                  <button
                    onClick={() => updateStatus(product.id, 'active')}
                    disabled={pendingId === product.id}
                    className="rounded-lg bg-primary px-3 py-1.5 text-xs font-semibold text-white disabled:opacity-60"
                  >
                    Akceptuj
                  </button>
                  <button
                    onClick={() => updateStatus(product.id, 'rejected')}
                    disabled={pendingId === product.id}
                    className="rounded-lg border border-red-300 px-3 py-1.5 text-xs font-semibold text-red-600 disabled:opacity-60"
                  >
                    Odrzuć
                  </button>
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
