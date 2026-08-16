import { Sidebar } from '@/components/Sidebar';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { ProductsTable } from './ProductsTable';

export default async function ProductsPage() {
  const supabase = await createSupabaseServerClient();

  const { data: products } = await supabase
    .from('products')
    .select(
      'id, title, price, status, created_at, profiles(username), product_images(image_url, is_main)',
    )
    .order('created_at', { ascending: false });

  return (
    <div className="flex min-h-screen">
      <Sidebar />
      <main className="flex-1 p-8">
        <h1 className="mb-6 text-2xl font-bold">Wszystkie produkty</h1>
        <ProductsTable products={products ?? []} />
      </main>
    </div>
  );
}
