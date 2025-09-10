// admin/app/page.tsx
'use client';

import Link from 'next/link';
import { ApiBar } from '../components/common';

export default function Home() {
  return (
    <main>
      <ApiBar title="Admin Home" />
      <ul style={{ lineHeight: 2 }}>
        <li><Link href="/notifications">Notifications</Link></li>
        <li><Link href="/trust">Trust Verification</Link></li>
      </ul>
    </main>
  );
}
