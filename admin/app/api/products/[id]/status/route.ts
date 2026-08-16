import { NextRequest, NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/lib/supabase/server';

const ALLOWED_STATUSES = ['active', 'rejected', 'pending', 'sold'];

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const { id } = await params;
  const { status } = await request.json();

  if (!ALLOWED_STATUSES.includes(status)) {
    return NextResponse.json({ error: 'Nieprawidłowy status.' }, { status: 400 });
  }

  const supabase = await createSupabaseServerClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) {
    return NextResponse.json({ error: 'Brak autoryzacji.' }, { status: 401 });
  }

  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single();
  if (profile?.role !== 'moderator' && profile?.role !== 'admin') {
    return NextResponse.json({ error: 'Brak uprawnień.' }, { status: 403 });
  }

  const { error } = await supabase.from('products').update({ status }).eq('id', id);
  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ ok: true });
}
