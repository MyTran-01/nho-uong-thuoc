import React, { useState } from 'react';
import { Button, Card, Checkbox, Chip } from '@heroui/react';

// Xem thử token trong ngữ cảnh thật của app Nhớ Thuốc, dựng bằng component HeroUI.
// Dữ liệu thuốc là hư cấu.

type Med = { id: string; name: string; dose: string; how: string; hue: string };

const MEDS: Med[] = [
  { id: 'a', name: 'Thuốc da liễu B', dose: '2 viên', how: 'Uống với nhiều nước', hue: '#f59e0b' },
  { id: 'b', name: 'Vitamin C', dose: '1 viên', how: 'Nhai hoặc nuốt', hue: '#f97316' },
  { id: 'c', name: 'Kẽm', dose: 'Nửa viên', how: 'Uống sau khi ăn no', hue: '#60a5fa' },
];

function Blister({ side, hue }: { side: 'front' | 'back'; hue: string }) {
  return (
    <svg viewBox="0 0 64 64" className="block h-full w-full" role="img" aria-label={side === 'front' ? 'Mặt trước vỉ' : 'Mặt sau vỉ'}>
      <rect x="0" y="0" width="64" height="64" fill={side === 'front' ? '#e5e7eb' : '#d1d5db'} />
      {side === 'front'
        ? [0, 1, 2].flatMap((r) => [0, 1].map((c) => (
            <ellipse key={`${r}${c}`} cx={20 + c * 24} cy={14 + r * 18} rx="8" ry="6" fill={hue} stroke="#00000022" />
          )))
        : [0, 1, 2, 3].map((i) => <rect key={i} x="8" y={12 + i * 11} width={i % 2 ? 36 : 48} height="4" rx="2" fill="#9ca3af" />)}
    </svg>
  );
}

function MedRow({ med, checked, onChange }: { med: Med; checked: boolean; onChange: (v: boolean) => void }) {
  return (
    <div className="flex items-center gap-3 py-3" onClick={() => onChange(!checked)} role="presentation">
      <div className="flex shrink-0 gap-1.5">
        {(['front', 'back'] as const).map((s) => (
          <div key={s} className="size-14 overflow-hidden rounded-[calc(var(--radius)*0.75)] border border-border">
            <Blister side={s} hue={med.hue} />
          </div>
        ))}
      </div>
      <div className="min-w-0 flex-1">
        <span className="block font-semibold leading-tight" style={{ fontSize: '1.05rem' }}>{med.name}</span>
        <span className="block leading-snug text-muted" style={{ fontSize: '0.9rem' }}>{med.dose} · {med.how}</span>
      </div>
      <div onClick={(e) => e.stopPropagation()}>
        <Checkbox isSelected={checked} onChange={onChange} aria-label={`Đã uống ${med.name}`}>
          <Checkbox.Control className="size-7">
            <Checkbox.Indicator />
          </Checkbox.Control>
        </Checkbox>
      </div>
    </div>
  );
}

const OFFSETS = ['15 phút', '30 phút', '45 phút', '60 phút'];

export function AppPreview() {
  const [checked, setChecked] = useState<Record<string, boolean>>({ a: true, b: true, c: true });
  const [offset, setOffset] = useState('30 phút');
  const missing = MEDS.filter((m) => !checked[m.id]).length;

  return (
    <section className="space-y-3" aria-labelledby="app-preview">
      <h3 id="app-preview" className="text-sm font-bold uppercase tracking-wider text-muted">
        Nhớ Thuốc · xem thử trong app (khung 390px)
      </h3>
      <div className="flex flex-wrap gap-6 overflow-x-auto">
        {/* Màn đánh dấu đã uống */}
        <div className="w-[390px] shrink-0 rounded-[2rem] bg-background p-4">
          <p className="text-muted" style={{ fontSize: '0.9rem' }}>7:15 · Sáng, sau khi ăn</p>
          <h4 className="font-bold leading-tight" style={{ fontSize: '1.6rem' }}>Tới giờ uống thuốc rồi</h4>
          <p className="mt-1 text-muted" style={{ fontSize: '1rem' }}>Bỏ dấu tích ở thuốc nào chưa uống.</p>
          <Card className="mt-4 px-4 py-1">
            <div className="divide-y divide-separator">
              {MEDS.map((m) => (
                <MedRow key={m.id} med={m} checked={checked[m.id]} onChange={(v) => setChecked({ ...checked, [m.id]: v })} />
              ))}
            </div>
          </Card>
          <Button variant="primary" fullWidth className="mt-5 h-[var(--button-height)] font-semibold" style={{ fontSize: '1.1rem' }}>
            {missing === 0 ? 'Đã uống' : `Đã uống (còn ${missing} thuốc chưa uống)`}
          </Button>
          <Button variant="tertiary" fullWidth className="mt-2 h-[var(--touch-min)]" style={{ fontSize: '1rem' }}>
            Hôm nay bỏ cữ này
          </Button>
        </div>

        {/* Thẻ Hôm nay + chip chọn + trạng thái */}
        <div className="w-[390px] shrink-0 space-y-4 rounded-[2rem] bg-background p-4">
          <Card className="p-4">
            <div className="flex items-start justify-between gap-2">
              <div>
                <p className="font-bold leading-none" style={{ fontSize: '2.2rem' }}>19:15</p>
                <p className="mt-1 font-semibold" style={{ fontSize: '1.1rem' }}>Tối, sau khi ăn</p>
                <p className="text-muted" style={{ fontSize: '0.9rem' }}>2 loại thuốc</p>
              </div>
              <Chip color="accent" variant="soft">Sắp tới</Chip>
            </div>
            <Button variant="secondary" fullWidth className="mt-4 h-[var(--button-height)]" style={{ fontSize: '1.05rem' }}>
              Xem thuốc cần uống
            </Button>
          </Card>

          <Card className="p-4">
            <p className="font-semibold" style={{ fontSize: '1.05rem' }}>Trước khi ăn sáng bao lâu?</p>
            <div className="mt-3 flex flex-wrap gap-2">
              {OFFSETS.map((o) => (
                <Button
                  key={o}
                  variant={o === offset ? 'primary' : 'outline'}
                  className="h-[var(--touch-min)] rounded-full px-4"
                  style={{ fontSize: '1rem' }}
                  onPress={() => setOffset(o)}
                >
                  {o}
                </Button>
              ))}
            </div>
            <p className="mt-2 text-muted" style={{ fontSize: '0.9rem' }}>Đơn không ghi thì để 30 phút.</p>
          </Card>

          <Card className="p-4">
            <p className="font-semibold" style={{ fontSize: '1.05rem' }}>Trạng thái trong lịch sử</p>
            <div className="mt-3 flex flex-wrap gap-2">
              <Chip color="success" variant="primary">✓ Đã uống đủ</Chip>
              <Chip color="warning" variant="primary">◐ Còn 1 thuốc chưa uống</Chip>
              <Chip color="default" variant="secondary">– Đã bỏ cữ</Chip>
              <Chip color="danger" variant="primary">! Chưa đánh dấu</Chip>
            </div>
          </Card>

          <Card className="p-4">
            <div className="flex items-center justify-between gap-3">
              <div>
                <p className="font-semibold" style={{ fontSize: '1.05rem' }}>Đơn Da liễu</p>
                <p className="text-muted" style={{ fontSize: '0.9rem' }}>4 loại thuốc · đã đủ 30 ngày</p>
              </div>
              <Button variant="danger" className="h-[var(--touch-min)]" style={{ fontSize: '0.95rem' }}>
                Đã uống hết đơn này
              </Button>
            </div>
          </Card>
        </div>
      </div>
    </section>
  );
}
