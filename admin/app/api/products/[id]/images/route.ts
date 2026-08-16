import { NextRequest, NextResponse } from 'next/server';
import { requireModerator } from '@/lib/requireModerator';

type ImageUpdate = { id: string; is_main: boolean; position: number };

/** Zapisuje okładkę i kolejność zdjęć — klient wysyła pełny, docelowy stan wszystkich zdjęć oferty. */
export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const { id } = await params;
  const { images } = (await request.json()) as { images: ImageUpdate[] };

  if (!Array.isArray(images) || images.length === 0) {
    return NextResponse.json({ error: 'Brak zdjęć do zapisania.' }, { status: 400 });
  }

  const { supabase, error } = await requireModerator();
  if (error) return error;

  for (const image of images) {
    const { error: updateError } = await supabase
      .from('product_images')
      .update({ is_main: image.is_main, position: image.position })
      .eq('id', image.id)
      .eq('product_id', id);
    if (updateError) {
      return NextResponse.json({ error: updateError.message }, { status: 500 });
    }
  }

  return NextResponse.json({ ok: true });
}
