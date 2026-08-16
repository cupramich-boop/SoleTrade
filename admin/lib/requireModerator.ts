import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/lib/supabase/server';

/** Zwraca supabase client gdy user jest moderatorem/adminem, inaczej gotową odpowiedź błędu. */
export async function requireModerator() {
  const supabase = await createSupabaseServerClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) {
    return { error: NextResponse.json({ error: 'Brak autoryzacji.' }, { status: 401 }) };
  }

  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single();
  if (profile?.role !== 'moderator' && profile?.role !== 'admin') {
    return { error: NextResponse.json({ error: 'Brak uprawnień.' }, { status: 403 }) };
  }

  return { supabase };
}
