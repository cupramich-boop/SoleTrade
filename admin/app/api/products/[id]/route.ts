import { NextRequest, NextResponse } from 'next/server';
import { requireModerator } from '@/lib/requireModerator';

const EDITABLE_FIELDS = [
  'title',
  'description',
  'price',
  'condition_days',
  'size',
  'material',
  'category_id',
  'status',
] as const;

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const { id } = await params;
  const body = await request.json();

  const update: Record<string, unknown> = {};
  for (const field of EDITABLE_FIELDS) {
    if (field in body) update[field] = body[field];
  }
  if (Object.keys(update).length === 0) {
    return NextResponse.json({ error: 'Brak pól do zapisania.' }, { status: 400 });
  }

  const { supabase, error } = await requireModerator();
  if (error) return error;

  const { error: updateError } = await supabase.from('products').update(update).eq('id', id);
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

  const { error: deleteError } = await supabase.from('products').delete().eq('id', id);
  if (deleteError) {
    return NextResponse.json({ error: deleteError.message }, { status: 500 });
  }

  return NextResponse.json({ ok: true });
}
