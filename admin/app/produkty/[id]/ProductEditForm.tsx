'use client';

import { useRouter } from 'next/navigation';
import { useState } from 'react';
import {
  PRODUCT_CONDITION_DAYS,
  PRODUCT_MATERIALS,
  PRODUCT_SIZES,
  PRODUCT_STATUSES,
  conditionDaysLabel,
} from '@/lib/productOptions';

type Product = {
  id: string;
  title: string;
  description: string;
  price: number;
  condition_days: number;
  size: string;
  material: string;
  category_id: string | null;
  status: string;
  is_featured: boolean;
};

type ProductImage = {
  id: string;
  image_url: string;
  is_main: boolean;
  position: number;
};

type Category = { id: string; name: string };

export function ProductEditForm({
  product,
  images,
  categories,
}: {
  product: Product;
  images: ProductImage[];
  categories: Category[];
}) {
  const router = useRouter();
  const [form, setForm] = useState({
    title: product.title,
    description: product.description,
    price: product.price,
    condition_days: product.condition_days,
    size: product.size,
    material: product.material,
    category_id: product.category_id ?? '',
    status: product.status,
    is_featured: product.is_featured,
  });
  const [imageList, setImageList] = useState(
    [...images].sort((a, b) => a.position - b.position),
  );
  const [saving, setSaving] = useState(false);
  const [savingImages, setSavingImages] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const [message, setMessage] = useState<string | null>(null);

  function setCover(id: string) {
    setImageList((list) => list.map((img) => ({ ...img, is_main: img.id === id })));
  }

  function moveImage(index: number, direction: -1 | 1) {
    setImageList((list) => {
      const next = [...list];
      const target = index + direction;
      if (target < 0 || target >= next.length) return list;
      [next[index], next[target]] = [next[target], next[index]];
      return next.map((img, i) => ({ ...img, position: i }));
    });
  }

  async function saveDetails() {
    setSaving(true);
    setMessage(null);
    const res = await fetch(`/api/products/${product.id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        ...form,
        price: Number(form.price),
        condition_days: Number(form.condition_days),
        category_id: form.category_id || null,
      }),
    });
    setSaving(false);
    if (res.ok) {
      setMessage('Zapisano zmiany.');
      router.refresh();
    } else {
      const { error } = await res.json();
      setMessage(`Błąd: ${error}`);
    }
  }

  async function saveImages() {
    setSavingImages(true);
    setMessage(null);
    const res = await fetch(`/api/products/${product.id}/images`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        images: imageList.map((img, i) => ({
          id: img.id,
          is_main: img.is_main,
          position: i,
        })),
      }),
    });
    setSavingImages(false);
    if (res.ok) {
      setMessage('Zapisano zdjęcia.');
      router.refresh();
    } else {
      const { error } = await res.json();
      setMessage(`Błąd: ${error}`);
    }
  }

  async function deleteProduct() {
    if (
      !confirm(
        `Na pewno chcesz trwale usunąć ofertę "${product.title}"? Tej operacji nie można cofnąć.`,
      )
    ) {
      return;
    }
    setDeleting(true);
    setMessage(null);
    const res = await fetch(`/api/products/${product.id}`, { method: 'DELETE' });
    if (res.ok) {
      router.push('/produkty');
    } else {
      setDeleting(false);
      const { error } = await res.json();
      setMessage(`Błąd: ${error}`);
    }
  }

  return (
    <div className="max-w-3xl space-y-8">
      <section className="rounded-2xl border border-primary-light bg-white p-6">
        <h2 className="mb-4 text-lg font-bold">Zdjęcia</h2>
        {imageList.length === 0 ? (
          <p className="text-sm text-gray-400">Brak zdjęć.</p>
        ) : (
          <div className="flex flex-wrap gap-4">
            {imageList.map((img, i) => (
              <div key={img.id} className="w-36 space-y-2">
                <div className="relative">
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img
                    src={img.image_url}
                    alt=""
                    className={`h-36 w-36 rounded-xl border-2 object-cover ${
                      img.is_main ? 'border-primary' : 'border-transparent'
                    }`}
                  />
                  {img.is_main && (
                    <span className="absolute left-1 top-1 rounded-full bg-primary px-2 py-0.5 text-[10px] font-bold text-white">
                      Okładka
                    </span>
                  )}
                </div>
                <div className="flex items-center justify-between gap-1">
                  <button
                    type="button"
                    onClick={() => moveImage(i, -1)}
                    disabled={i === 0}
                    className="rounded-md border border-primary-light px-2 py-1 text-xs disabled:opacity-30"
                  >
                    ←
                  </button>
                  {!img.is_main && (
                    <button
                      type="button"
                      onClick={() => setCover(img.id)}
                      className="flex-1 rounded-md border border-primary px-2 py-1 text-xs font-medium text-primary"
                    >
                      Ustaw jako okładkę
                    </button>
                  )}
                  <button
                    type="button"
                    onClick={() => moveImage(i, 1)}
                    disabled={i === imageList.length - 1}
                    className="rounded-md border border-primary-light px-2 py-1 text-xs disabled:opacity-30"
                  >
                    →
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
        {imageList.length > 0 && (
          <button
            type="button"
            onClick={saveImages}
            disabled={savingImages}
            className="mt-4 rounded-lg bg-primary px-4 py-2 text-sm font-semibold text-white disabled:opacity-60"
          >
            {savingImages ? 'Zapisywanie...' : 'Zapisz zdjęcia'}
          </button>
        )}
      </section>

      <section className="rounded-2xl border border-primary-light bg-white p-6">
        <h2 className="mb-4 text-lg font-bold">Dane oferty</h2>
        <div className="grid grid-cols-2 gap-4">
          <label className="col-span-2 block">
            <span className="mb-1 block text-xs font-medium text-gray-500">Tytuł</span>
            <input
              value={form.title}
              onChange={(e) => setForm({ ...form, title: e.target.value })}
              className="w-full rounded-lg border border-primary-light px-3 py-2 text-sm"
            />
          </label>
          <label className="col-span-2 block">
            <span className="mb-1 block text-xs font-medium text-gray-500">Opis</span>
            <textarea
              value={form.description}
              onChange={(e) => setForm({ ...form, description: e.target.value })}
              rows={4}
              className="w-full rounded-lg border border-primary-light px-3 py-2 text-sm"
            />
          </label>
          <label className="block">
            <span className="mb-1 block text-xs font-medium text-gray-500">Cena (zł)</span>
            <input
              type="number"
              value={form.price}
              onChange={(e) => setForm({ ...form, price: Number(e.target.value) })}
              className="w-full rounded-lg border border-primary-light px-3 py-2 text-sm"
            />
          </label>
          <label className="block">
            <span className="mb-1 block text-xs font-medium text-gray-500">Używane (dni)</span>
            <select
              value={form.condition_days}
              onChange={(e) => setForm({ ...form, condition_days: Number(e.target.value) })}
              className="w-full rounded-lg border border-primary-light px-3 py-2 text-sm"
            >
              {PRODUCT_CONDITION_DAYS.map((d) => (
                <option key={d} value={d}>
                  {conditionDaysLabel(d)}
                </option>
              ))}
            </select>
          </label>
          <label className="block">
            <span className="mb-1 block text-xs font-medium text-gray-500">Rozmiar</span>
            <select
              value={form.size}
              onChange={(e) => setForm({ ...form, size: e.target.value })}
              className="w-full rounded-lg border border-primary-light px-3 py-2 text-sm"
            >
              {PRODUCT_SIZES.map((s) => (
                <option key={s} value={s}>
                  {s}
                </option>
              ))}
            </select>
          </label>
          <label className="block">
            <span className="mb-1 block text-xs font-medium text-gray-500">Materiał</span>
            <select
              value={form.material}
              onChange={(e) => setForm({ ...form, material: e.target.value })}
              className="w-full rounded-lg border border-primary-light px-3 py-2 text-sm"
            >
              {PRODUCT_MATERIALS.map((m) => (
                <option key={m} value={m}>
                  {m}
                </option>
              ))}
            </select>
          </label>
          <label className="block">
            <span className="mb-1 block text-xs font-medium text-gray-500">Kategoria</span>
            <select
              value={form.category_id}
              onChange={(e) => setForm({ ...form, category_id: e.target.value })}
              className="w-full rounded-lg border border-primary-light px-3 py-2 text-sm"
            >
              <option value="">Brak</option>
              {categories.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </select>
          </label>
          <label className="block">
            <span className="mb-1 block text-xs font-medium text-gray-500">Status</span>
            <select
              value={form.status}
              onChange={(e) => setForm({ ...form, status: e.target.value })}
              className="w-full rounded-lg border border-primary-light px-3 py-2 text-sm"
            >
              {PRODUCT_STATUSES.map((s) => (
                <option key={s} value={s}>
                  {s}
                </option>
              ))}
            </select>
          </label>
          <label className="col-span-2 flex items-center gap-2">
            <input
              type="checkbox"
              checked={form.is_featured}
              onChange={(e) => setForm({ ...form, is_featured: e.target.checked })}
              className="h-4 w-4 rounded border-primary-light text-primary"
            />
            <span className="text-sm font-medium text-gray-700">
              Polecane (widoczne w karuzeli &quot;Polecane&quot; na stronie głównej)
            </span>
          </label>
        </div>
        <button
          type="button"
          onClick={saveDetails}
          disabled={saving}
          className="mt-6 rounded-lg bg-primary px-4 py-2 text-sm font-semibold text-white disabled:opacity-60"
        >
          {saving ? 'Zapisywanie...' : 'Zapisz zmiany'}
        </button>
        {message && <p className="mt-3 text-sm text-gray-600">{message}</p>}
      </section>

      <section className="rounded-2xl border border-red-200 bg-red-50 p-6">
        <h2 className="mb-1 text-lg font-bold text-red-700">Strefa niebezpieczna</h2>
        <p className="mb-4 text-sm text-red-600">
          Trwałe usunięcie oferty wraz ze zdjęciami. Tej operacji nie można cofnąć.
        </p>
        <button
          type="button"
          onClick={deleteProduct}
          disabled={deleting}
          className="rounded-lg border border-red-300 bg-white px-4 py-2 text-sm font-semibold text-red-600 disabled:opacity-60"
        >
          {deleting ? 'Usuwanie...' : 'Usuń ofertę na zawsze'}
        </button>
      </section>
    </div>
  );
}
