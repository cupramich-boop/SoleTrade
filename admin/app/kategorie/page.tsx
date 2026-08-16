import { Sidebar } from '@/components/Sidebar';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { CategoriesManager } from './CategoriesManager';

export default async function CategoriesPage() {
  const supabase = await createSupabaseServerClient();

  const { data: categories } = await supabase
    .from('categories')
    .select('id, name, icon_url')
    .order('name');

  return (
    <div className="flex min-h-screen">
      <Sidebar />
      <main className="flex-1 p-8">
        <h1 className="mb-6 text-2xl font-bold">Kategorie</h1>
        <CategoriesManager initialCategories={categories ?? []} />
      </main>
    </div>
  );
}
