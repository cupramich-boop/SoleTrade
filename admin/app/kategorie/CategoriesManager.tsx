'use client';

import { useRef, useState } from 'react';
import { useRouter } from 'next/navigation';
import { createSupabaseBrowserClient } from '@/lib/supabase/client';

type Category = { id: string; name: string; icon_url: string | null };

const ALLOWED_EXTENSIONS = ['jpg', 'jpeg', 'png', 'webp'];

function extOf(fileName: string) {
  return fileName.split('.').pop()?.toLowerCase() ?? '';
}

async function uploadIcon(file: File): Promise<string> {
  const ext = extOf(file.name);
  if (!ALLOWED_EXTENSIONS.includes(ext)) {
    throw new Error('Obsługiwane są tylko pliki JPG, PNG i WEBP.');
  }
  const supabase = createSupabaseBrowserClient();
  const path = `categories/${crypto.randomUUID()}.${ext}`;
  const { error } = await supabase.storage.from('product-images').upload(path, file, {
    upsert: true,
    contentType: file.type,
  });
  if (error) throw error;
  return supabase.storage.from('product-images').getPublicUrl(path).data.publicUrl;
}

export function CategoriesManager({ initialCategories }: { initialCategories: Category[] }) {
  const router = useRouter();
  const [categories, setCategories] = useState(initialCategories);
  const [newName, setNewName] = useState('');
  const [creating, setCreating] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const newIconRef = useRef<HTMLInputElement>(null);

  async function addCategory() {
    if (!newName.trim()) {
      setError('Podaj nazwę kategorii.');
      return;
    }
    setCreating(true);
    setError(null);
    try {
      let icon_url: string | null = null;
      const file = newIconRef.current?.files?.[0];
      if (file) icon_url = await uploadIcon(file);

      const res = await fetch('/api/categories', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: newName.trim(), icon_url }),
      });
      if (!res.ok) {
        const { error: msg } = await res.json();
        throw new Error(msg);
      }
      const { category } = await res.json();
      setCategories((list) => [...list, category].sort((a, b) => a.name.localeCompare(b.name)));
      setNewName('');
      if (newIconRef.current) newIconRef.current.value = '';
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Nie udało się dodać kategorii.');
    } finally {
      setCreating(false);
    }
  }

  async function renameCategory(id: string, name: string) {
    await fetch(`/api/categories/${id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name }),
    });
    router.refresh();
  }

  async function changeIcon(id: string, file: File) {
    setError(null);
    try {
      const icon_url = await uploadIcon(file);
      setCategories((list) => list.map((c) => (c.id === id ? { ...c, icon_url } : c)));
      await fetch(`/api/categories/${id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ icon_url }),
      });
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Nie udało się zmienić zdjęcia.');
    }
  }

  async function deleteCategory(id: string) {
    if (!confirm('Usunąć tę kategorię? Oferty w niej stracą przypisaną kategorię.')) return;
    setCategories((list) => list.filter((c) => c.id !== id));
    await fetch(`/api/categories/${id}`, { method: 'DELETE' });
    router.refresh();
  }

  return (
    <div className="max-w-2xl space-y-6">
      <section className="rounded-2xl border border-primary-light bg-white p-6">
        <h2 className="mb-4 text-lg font-bold">Nowa kategoria</h2>
        <div className="flex flex-wrap items-end gap-3">
          <label className="block">
            <span className="mb-1 block text-xs font-medium text-gray-500">Nazwa</span>
            <input
              value={newName}
              onChange={(e) => setNewName(e.target.value)}
              className="rounded-lg border border-primary-light px-3 py-2 text-sm"
              placeholder="np. Rajstopy"
            />
          </label>
          <label className="block">
            <span className="mb-1 block text-xs font-medium text-gray-500">Zdjęcie (opcjonalnie)</span>
            <input ref={newIconRef} type="file" accept="image/png,image/jpeg,image/webp" className="text-sm" />
          </label>
          <button
            type="button"
            onClick={addCategory}
            disabled={creating}
            className="rounded-lg bg-primary px-4 py-2 text-sm font-semibold text-white disabled:opacity-60"
          >
            {creating ? 'Dodawanie...' : 'Dodaj kategorię'}
          </button>
        </div>
        {error && <p className="mt-3 text-sm text-red-600">{error}</p>}
      </section>

      <section className="overflow-hidden rounded-2xl border border-primary-light bg-white">
        <table className="w-full text-sm">
          <thead className="bg-primary-light/40 text-left text-gray-600">
            <tr>
              <th className="px-4 py-3">Zdjęcie</th>
              <th className="px-4 py-3">Nazwa</th>
              <th className="px-4 py-3">Akcje</th>
            </tr>
          </thead>
          <tbody>
            {categories.map((category) => (
              <CategoryRow
                key={category.id}
                category={category}
                onRename={renameCategory}
                onChangeIcon={changeIcon}
                onDelete={deleteCategory}
              />
            ))}
          </tbody>
        </table>
        {categories.length === 0 && (
          <p className="p-8 text-center text-gray-400">Brak kategorii.</p>
        )}
      </section>
    </div>
  );
}

function CategoryRow({
  category,
  onRename,
  onChangeIcon,
  onDelete,
}: {
  category: Category;
  onRename: (id: string, name: string) => void;
  onChangeIcon: (id: string, file: File) => void;
  onDelete: (id: string) => void;
}) {
  const [name, setName] = useState(category.name);
  const iconRef = useRef<HTMLInputElement>(null);

  return (
    <tr className="border-t border-primary-light">
      <td className="px-4 py-3">
        <button
          type="button"
          onClick={() => iconRef.current?.click()}
          className="block h-12 w-12 overflow-hidden rounded-lg bg-primary-light"
          title="Zmień zdjęcie"
        >
          {category.icon_url ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={category.icon_url} alt="" className="h-full w-full object-cover" />
          ) : null}
        </button>
        <input
          ref={iconRef}
          type="file"
          accept="image/png,image/jpeg,image/webp"
          className="hidden"
          onChange={(e) => {
            const file = e.target.files?.[0];
            if (file) onChangeIcon(category.id, file);
          }}
        />
      </td>
      <td className="px-4 py-3">
        <input
          value={name}
          onChange={(e) => setName(e.target.value)}
          onBlur={() => name.trim() && name !== category.name && onRename(category.id, name.trim())}
          className="w-full rounded-lg border border-transparent px-2 py-1 font-medium hover:border-primary-light focus:border-primary-light"
        />
      </td>
      <td className="px-4 py-3">
        <button
          type="button"
          onClick={() => onDelete(category.id)}
          className="rounded-lg border border-red-300 px-3 py-1.5 text-xs font-semibold text-red-600"
        >
          Usuń
        </button>
      </td>
    </tr>
  );
}
