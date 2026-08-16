import { Sidebar } from '@/components/Sidebar';
import { createSupabaseServerClient } from '@/lib/supabase/server';

export default async function DashboardPage() {
  const supabase = await createSupabaseServerClient();

  const [{ count: pendingCount }, { count: activeCount }, { count: userCount }] =
    await Promise.all([
      supabase.from('products').select('*', { count: 'exact', head: true }).eq('status', 'pending'),
      supabase.from('products').select('*', { count: 'exact', head: true }).eq('status', 'active'),
      supabase.from('profiles').select('*', { count: 'exact', head: true }),
    ]);

  const { data: recentPending } = await supabase
    .from('products')
    .select('id, title, price, created_at')
    .eq('status', 'pending')
    .order('created_at', { ascending: false })
    .limit(5);

  const stats = [
    { label: 'Oferty do moderacji', value: pendingCount ?? 0 },
    { label: 'Aktywne oferty', value: activeCount ?? 0 },
    { label: 'Użytkownicy', value: userCount ?? 0 },
  ];

  return (
    <div className="flex min-h-screen">
      <Sidebar />
      <main className="flex-1 p-8">
        <h1 className="mb-6 text-2xl font-bold">Dashboard</h1>
        <div className="mb-8 grid grid-cols-1 gap-4 sm:grid-cols-3">
          {stats.map((stat) => (
            <div key={stat.label} className="rounded-2xl border border-primary-light bg-white p-6">
              <p className="text-sm text-gray-500">{stat.label}</p>
              <p className="mt-2 text-3xl font-extrabold text-primary">{stat.value}</p>
            </div>
          ))}
        </div>

        <h2 className="mb-4 text-lg font-semibold">Ostatnie oferty do moderacji</h2>
        <div className="overflow-hidden rounded-2xl border border-primary-light bg-white">
          <table className="w-full text-sm">
            <thead className="bg-primary-light/40 text-left text-gray-600">
              <tr>
                <th className="px-4 py-3">Tytuł</th>
                <th className="px-4 py-3">Cena</th>
                <th className="px-4 py-3">Dodano</th>
              </tr>
            </thead>
            <tbody>
              {(recentPending ?? []).map((product) => (
                <tr key={product.id} className="border-t border-primary-light">
                  <td className="px-4 py-3">{product.title}</td>
                  <td className="px-4 py-3">{product.price} zł</td>
                  <td className="px-4 py-3 text-gray-500">
                    {new Date(product.created_at).toLocaleDateString('pl-PL')}
                  </td>
                </tr>
              ))}
              {(recentPending ?? []).length === 0 && (
                <tr>
                  <td colSpan={3} className="px-4 py-6 text-center text-gray-400">
                    Brak nowych ofert do moderacji.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </main>
    </div>
  );
}
