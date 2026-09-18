import { useState, useEffect } from 'react';
import { Search, Settings, User } from 'lucide-react';
import DenDenMushi from './DenDenMushi';
import jollyRoger from '@/assets/jolly-roger.png';

interface NavbarProps {
  searchQuery: string;
  onSearchChange: (q: string) => void;
}

const Navbar = ({ searchQuery, onSearchChange }: NavbarProps) => {
  const [time, setTime] = useState(new Date());

  useEffect(() => {
    const t = setInterval(() => setTime(new Date()), 1000);
    return () => clearInterval(t);
  }, []);

  return (
    <header className="fixed top-0 left-0 right-0 z-50 backdrop-blur-xl border-b" style={{ borderColor: 'hsl(var(--border))' }}>
      <div
        className="h-[72px] flex items-center justify-between px-4 lg:px-8"
        style={{ backgroundColor: 'hsl(240 50% 8% / 0.8)' }}
      >
        {/* Left: Logo */}
        <div className="flex items-center gap-3">
          {/* Jolly Roger */}
          <div className="relative" style={{ animation: 'jolly-pulse 3s ease-in-out infinite' }}>
            <img src={jollyRoger} alt="Nix Flake Pirates Jolly Roger" width={44} height={44} className="drop-shadow-[0_0_8px_hsl(340,100%,50%)]" />
          </div>
          <h1 className="font-orbitron text-lg font-black tracking-widest neon-text-red hidden sm:block" style={{ color: 'hsl(340,100%,50%)' }}>
            NIX FLAKE PIRATES
          </h1>
        </div>

        {/* Center: Log Pose + Search */}
        <div className="flex items-center gap-4 flex-1 max-w-md mx-4">
          {/* Log Pose */}
          <div className="hidden md:flex items-center justify-center w-9 h-9 rounded-full border" style={{ borderColor: 'hsl(190,100%,50%,0.3)' }}>
            <svg viewBox="0 0 24 24" width={18} height={18} fill="none">
              <circle cx="12" cy="12" r="10" stroke="hsl(190,100%,50%)" strokeWidth="1.5" opacity="0.4" />
              <circle cx="12" cy="12" r="6" stroke="hsl(190,100%,50%)" strokeWidth="1" opacity="0.25" />
              <circle cx="12" cy="12" r="2" fill="hsl(190,100%,50%)" opacity="0.6" />
              <line x1="12" y1="12" x2="12" y2="4" stroke="hsl(190,100%,50%)" strokeWidth="1.5" strokeLinecap="round"
                style={{ transformOrigin: '12px 12px', animation: 'log-pose-rotate 8s linear infinite' }}
              />
            </svg>
          </div>
          {/* Search */}
          <div className="relative flex-1">
            <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground" />
            <input
              type="text"
              value={searchQuery}
              onChange={e => onSearchChange(e.target.value)}
              placeholder="Search crew services..."
              className="w-full bg-transparent border rounded-lg pl-9 pr-3 py-2 text-sm font-space placeholder:text-muted-foreground focus:outline-none focus:ring-1"
              style={{
                borderColor: 'hsl(var(--border))',
                color: 'hsl(var(--foreground))',
              }}
              onFocus={e => { e.currentTarget.style.borderColor = 'hsl(190,100%,50%)'; e.currentTarget.style.boxShadow = '0 0 12px hsl(190,100%,50%,0.3)'; }}
              onBlur={e => { e.currentTarget.style.borderColor = 'hsl(var(--border))'; e.currentTarget.style.boxShadow = 'none'; }}
            />
          </div>
        </div>

        {/* Right: Settings, Time, Avatar */}
        <div className="flex items-center gap-3">
          <Settings size={18} className="text-muted-foreground hover:text-foreground transition-colors cursor-pointer" />
          <span className="text-xs font-orbitron text-muted-foreground hidden lg:block">
            {time.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
          </span>
          <div className="w-8 h-8 rounded-full border-2 flex items-center justify-center" style={{ borderColor: 'hsl(190,100%,50%,0.5)' }}>
            <User size={16} className="text-muted-foreground" />
          </div>
        </div>
      </div>

      {/* Stats bar */}
      <div
        className="flex items-center justify-center gap-4 lg:gap-8 py-1.5 text-[10px] font-orbitron tracking-wider"
        style={{ backgroundColor: 'hsl(240 50% 6% / 0.9)' }}
      >
        <span>🏴‍☠️ <span className="text-crew-luffy">30/30</span> CREW</span>
        <span>📡 <span className="text-crew-vegapunk">7</span> SATELLITES</span>
        <span>⛵ <span className="text-crew-zoro">99.8%</span></span>
        <span className="text-muted-foreground">{time.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', hour12: true }).toUpperCase()}</span>
      </div>

      {/* Animated neon gradient bottom border */}
      <div
        className="h-[1px] shimmer-border"
        style={{
          background: 'linear-gradient(90deg, transparent, hsl(340,100%,50%), hsl(280,100%,50%), hsl(190,100%,50%), transparent)',
        }}
      />
    </header>
  );
};

export default Navbar;
