import { notFound } from 'next/navigation';
import { Sidebar } from '@/components/Sidebar';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { ProductEditForm } from './ProductEditForm';

export default async function ProductEditPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const supabase = await createSupabaseServerClient();

  const [{ data: product }, { data: images }, { data: categories }] = await Promise.all([
    supabase.from('products').select('*').eq('id', id).single(),
    supabase
      .from('product_images')
      .select('id, image_url, is_main, position')
      .eq('product_id', id)
      .order('position', { ascending: true }),
    supabase.from('categories').select('id, name').order('name'),
  ]);

  if (!product) notFound();

  return (
    <div className="flex min-h-screen">
      <Sidebar />
      <main className="flex-1 p-8">
        <h1 className="mb-6 text-2xl font-bold">Edycja oferty</h1>
        <ProductEditForm
          product={product}
          images={images ?? []}
          categories={categories ?? []}
        />
      </main>
    </div>
  );
}
