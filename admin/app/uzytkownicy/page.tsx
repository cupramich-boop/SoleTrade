import { Sidebar } from '@/components/Sidebar';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { UsersTable } from './UsersTable';

export default async function UsersPage() {
  const supabase = await createSupabaseServerClient();

  const { data: profiles } = await supabase
    .from('profiles')
    .select('id, username, rating_score, total_sold, role')
    .order('username');

  return (
    <div className="flex min-h-screen">
      <Sidebar />
      <main className="flex-1 p-8">
        <h1 className="mb-6 text-2xl font-bold">Użytkownicy</h1>
        <UsersTable profiles={profiles ?? []} />
      </main>
    </div>
  );
}
