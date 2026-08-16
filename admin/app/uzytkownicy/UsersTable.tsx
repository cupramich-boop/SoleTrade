'use client';

import { useState } from 'react';

type Profile = {
  id: string;
  username: string;
  rating_score: number;
  total_sold: number;
  role: string;
};

export function UsersTable({ profiles }: { profiles: Profile[] }) {
  const [bannedIds, setBannedIds] = useState<Set<string>>(new Set());
  const [pendingId, setPendingId] = useState<string | null>(null);

  async function banUser(id: string) {
    if (!confirm('Na pewno chcesz zablokować to konto?')) return;
    setPendingId(id);
    const res = await fetch(`/api/users/${id}/ban`, { method: 'POST' });
    if (res.ok) {
      setBannedIds((prev) => new Set(prev).add(id));
    }
    setPendingId(null);
  }

  return (
    <div className="overflow-hidden rounded-2xl border border-primary-light bg-white">
      <table className="w-full text-sm">
        <thead className="bg-primary-light/40 text-left text-gray-600">
          <tr>
            <th className="px-4 py-3">Nazwa użytkownika</th>
            <th className="px-4 py-3">Ocena</th>
            <th className="px-4 py-3">Sprzedane</th>
            <th className="px-4 py-3">Rola</th>
            <th className="px-4 py-3">Akcje</th>
          </tr>
        </thead>
        <tbody>
          {profiles.map((profile) => (
            <tr key={profile.id} className="border-t border-primary-light">
              <td className="px-4 py-3 font-medium">{profile.username}</td>
              <td className="px-4 py-3">{profile.rating_score.toFixed(1)}</td>
              <td className="px-4 py-3">{profile.total_sold}</td>
              <td className="px-4 py-3 capitalize text-gray-500">{profile.role}</td>
              <td className="px-4 py-3">
                {bannedIds.has(profile.id) ? (
                  <span className="text-xs font-semibold text-red-600">Zablokowany</span>
                ) : (
                  <button
                    onClick={() => banUser(profile.id)}
                    disabled={pendingId === profile.id}
                    className="rounded-lg border border-red-300 px-3 py-1.5 text-xs font-semibold text-red-600 disabled:opacity-60"
                  >
                    Zablokuj konto
                  </button>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
