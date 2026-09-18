import { useMemo } from 'react';

const particles = Array.from({ length: 40 }, (_, i) => ({
  id: i,
  x: Math.random() * 100,
  y: Math.random() * 100,
  size: 2 + Math.random() * 3,
  duration: 6 + Math.random() * 8,
  delay: Math.random() * 5,
  isJolly: Math.random() > 0.85,
  color: Math.random() > 0.5 ? 'hsl(190,100%,50%)' : 'hsl(300,100%,50%)',
}));

const Background = () => {
  const memoParticles = useMemo(() => particles, []);

  return (
    <div className="fixed inset-0 overflow-hidden pointer-events-none" style={{ zIndex: 0 }}>
      {/* Base gradient */}
      <div
        className="absolute inset-0"
        style={{ background: 'linear-gradient(180deg, #0a0a1f 0%, #1a0a2e 50%, #0a0a1f 100%)' }}
      />

      {/* Holographic grid */}
      <div
        className="absolute inset-0 opacity-[0.03]"
        style={{
          backgroundImage: `
            linear-gradient(hsl(280,100%,50%,0.3) 1px, transparent 1px),
            linear-gradient(90deg, hsl(280,100%,50%,0.3) 1px, transparent 1px)
          `,
          backgroundSize: '80px 80px',
          animation: 'gradient-border 8s ease-in-out infinite',
        }}
      />

      {/* Fog layer 1 - Thousand Sunny silhouette */}
      <div
        className="absolute top-1/3 w-full h-48 opacity-[0.035]"
        style={{
          background: 'radial-gradient(ellipse 300px 80px at center, hsl(190,100%,50%), transparent)',
          animation: 'fog-drift-right 120s linear infinite',
        }}
      />

      {/* Fog layer 2 - Egghead dome */}
      <div
        className="absolute top-1/2 w-full h-64 opacity-[0.025]"
        style={{
          background: 'radial-gradient(ellipse 400px 120px at center, hsl(280,100%,50%), transparent)',
          animation: 'fog-drift-left 90s linear infinite',
        }}
      />

      {/* Fog layer 3 */}
      <div
        className="absolute top-2/3 w-full h-32 opacity-[0.02]"
        style={{
          background: 'radial-gradient(ellipse 250px 60px at center, hsl(340,100%,50%), transparent)',
          animation: 'fog-drift-right 150s linear infinite',
        }}
      />

      {/* Floating particles */}
      {memoParticles.map(p => (
        <div
          key={p.id}
          className="absolute rounded-full"
          style={{
            left: `${p.x}%`,
            top: `${p.y}%`,
            width: p.isJolly ? 0 : p.size,
            height: p.isJolly ? 0 : p.size,
            backgroundColor: p.isJolly ? 'transparent' : p.color,
            opacity: 0.4,
            animation: `particle-float ${p.duration}s ease-in-out infinite`,
            animationDelay: `${p.delay}s`,
            fontSize: p.isJolly ? '8px' : undefined,
          }}
        >
          {p.isJolly && '☠'}
        </div>
      ))}
    </div>
  );
};

export default Background;
