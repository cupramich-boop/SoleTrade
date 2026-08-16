import { Sidebar } from '@/components/Sidebar';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { ModerationTable } from './ModerationTable';

export default async function ModerationPage() {
  const supabase = await createSupabaseServerClient();

  const { data: products } = await supabase
    .from('products')
    .select('id, title, price, size, material, condition_days, status, created_at, profiles(username)')
    .eq('status', 'pending')
    .order('created_at', { ascending: true });

  return (
    <div className="flex min-h-screen">
      <Sidebar />
      <main className="flex-1 p-8">
        <h1 className="mb-6 text-2xl font-bold">Moderacja ofert</h1>
        <ModerationTable products={products ?? []} />
      </main>
    </div>
  );
}
