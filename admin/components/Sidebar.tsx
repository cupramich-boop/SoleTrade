import Link from 'next/link';

const links = [
  { href: '/', label: 'Dashboard' },
  { href: '/moderacja', label: 'Moderacja ofert' },
  { href: '/produkty', label: 'Wszystkie produkty' },
  { href: '/uzytkownicy', label: 'Użytkownicy' },
];

export function Sidebar() {
  return (
    <aside className="w-64 shrink-0 border-r border-primary-light bg-white p-6">
      <div className="mb-8 flex items-center gap-2">
        <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-primary-light text-primary">
          ♥
        </div>
        <span className="text-lg font-extrabold">SoleTrade</span>
      </div>
      <nav className="flex flex-col gap-1">
        {links.map((link) => (
          <Link
            key={link.href}
            href={link.href}
            className="rounded-lg px-3 py-2 text-sm font-medium text-gray-700 hover:bg-primary-light hover:text-primary"
          >
            {link.label}
          </Link>
        ))}
      </nav>
    </aside>
  );
}
