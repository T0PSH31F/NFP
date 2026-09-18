import { useState } from 'react';
import Background from '@/components/dashboard/Background';
import Navbar from '@/components/dashboard/Navbar';
import CategorySection from '@/components/dashboard/CategorySection';
import VegapunkConstellation from '@/components/dashboard/VegapunkConstellation';
import { categories } from '@/data/services';

const Index = () => {
  const [searchQuery, setSearchQuery] = useState('');

  const vegapunk = categories.find(c => c.id === 'vegapunk')!;
  const otherCategories = categories.filter(c => c.id !== 'vegapunk');

  return (
    <div className="min-h-screen relative grain-overlay">
      <Background />
      <Navbar searchQuery={searchQuery} onSearchChange={setSearchQuery} />

      {/* Main content */}
      <main className="relative z-10 pt-[120px] px-4 lg:px-8 pb-12 max-w-[1600px] mx-auto">
        {/* Render categories in order: luffy, zoro, nami, sanji, then vegapunk, then robin, chopper */}
        {otherCategories.slice(0, 4).map(cat => (
          <CategorySection key={cat.id} category={cat} searchQuery={searchQuery} />
        ))}

        {/* Vegapunk Records - special constellation layout */}
        <VegapunkConstellation services={vegapunk.services} searchQuery={searchQuery} />

        {/* Robin & Chopper */}
        {otherCategories.slice(4).map(cat => (
          <CategorySection key={cat.id} category={cat} searchQuery={searchQuery} />
        ))}
      </main>
    </div>
  );
};

export default Index;
