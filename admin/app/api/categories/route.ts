import { NextRequest, NextResponse } from 'next/server';
import { requireModerator } from '@/lib/requireModerator';

export async function POST(request: NextRequest) {
  const { name, icon_url } = await request.json();

  if (!name || typeof name !== 'string' || !name.trim()) {
    return NextResponse.json({ error: 'Nazwa kategorii jest wymagana.' }, { status: 400 });
  }

  const { supabase, error } = await requireModerator();
  if (error) return error;

  const { data, error: insertError } = await supabase
    .from('categories')
    .insert({ name: name.trim(), icon_url: icon_url || null })
    .select()
    .single();

  if (insertError) {
    return NextResponse.json({ error: insertError.message }, { status: 500 });
  }

  return NextResponse.json({ category: data });
}
