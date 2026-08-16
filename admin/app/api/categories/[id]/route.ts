import { NextRequest, NextResponse } from 'next/server';
import { requireModerator } from '@/lib/requireModerator';

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const { id } = await params;
  const body = await request.json();

  const update: Record<string, unknown> = {};
  if ('name' in body) update.name = body.name;
  if ('icon_url' in body) update.icon_url = body.icon_url;
  if (Object.keys(update).length === 0) {
    return NextResponse.json({ error: 'Brak pól do zapisania.' }, { status: 400 });
  }

  const { supabase, error } = await requireModerator();
  if (error) return error;

  const { error: updateError } = await supabase.from('categories').update(update).eq('id', id);
  if (updateError) {
    return NextResponse.json({ error: updateError.message }, { status: 500 });
  }

  return NextResponse.json({ ok: true });
}

export async function DELETE(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const { id } = await params;

  const { supabase, error } = await requireModerator();
  if (error) return error;

  const { error: deleteError } = await supabase.from('categories').delete().eq('id', id);
  if (deleteError) {
    return NextResponse.json({ error: deleteError.message }, { status: 500 });
  }

  return NextResponse.json({ ok: true });
}
