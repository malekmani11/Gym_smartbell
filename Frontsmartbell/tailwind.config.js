/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/**/*.{html,ts}",
  ],
  theme: {
    extend: {
      colors: {
        gold: {
          light: '#F5D77A',
          main: '#D4AF37',
          DEFAULT: '#D4AF37',
          dark: '#A68523',
          darker: '#7A6118',
        },
        black: {
          bg: '#0A0A0A',
          card: '#141414',
          sidebar: '#0F0F0F',
          DEFAULT: '#000000',
        },
        anthracite: {
          DEFAULT: '#1E1E1E',
          light: '#2A2A2A',
          dark: '#161616',
        },
      },
      fontFamily: {
        montserrat: ['Montserrat', 'sans-serif'],
        playfair: ['Playfair Display', 'serif'],
        inter: ['Inter', 'sans-serif'],
      },
      boxShadow: {
        'gold':      '0 2px 8px rgba(212, 175, 55, 0.25), 0 0 14px rgba(212, 175, 55, 0.12)',
        'gold-lg':   '0 4px 20px rgba(212, 175, 55, 0.35), 0 0 30px rgba(212, 175, 55, 0.15)',
        'gold-glow': '0 0 40px rgba(212, 175, 55, 0.3)',
        'card':      '0 4px 20px rgba(0, 0, 0, 0.5), 0 1px 3px rgba(0, 0, 0, 0.3)',
        'card-hover':'0 8px 40px rgba(0, 0, 0, 0.6), 0 0 24px rgba(212, 175, 55, 0.07)',
        'inner-top': 'inset 0 1px 0 rgba(255, 255, 255, 0.05)',
      },
      backgroundImage: {
        'gold-gradient': 'linear-gradient(135deg, #D4AF37 0%, #F5D77A 50%, #D4AF37 100%)',
        'gold-gradient-subtle': 'linear-gradient(135deg, rgba(212,175,55,0.1) 0%, rgba(245,215,122,0.05) 100%)',
        'dark-gradient': 'linear-gradient(180deg, #0A0A0A 0%, #141414 100%)',
      },
      borderColor: {
        'gold-subtle': 'rgba(212, 175, 55, 0.2)',
      },
      animation: {
        'shimmer':      'shimmer 2s linear infinite',
        'pulse-gold':   'pulse-gold 2.5s ease-in-out infinite',
        'fade-in':      'fadeIn 0.4s ease-out',
        'fade-in-up':   'fadeInUp 0.45s cubic-bezier(0.16, 1, 0.3, 1)',
        'slide-up':     'slideUp 0.35s cubic-bezier(0.16, 1, 0.3, 1)',
        'glow-breathe': 'glowBreathe 4s ease-in-out infinite',
      },
      keyframes: {
        shimmer: {
          '0%':   { backgroundPosition: '-200% 0' },
          '100%': { backgroundPosition:  '200% 0' },
        },
        'pulse-gold': {
          '0%, 100%': { boxShadow: '0 0 12px rgba(212, 175, 55, 0.12)' },
          '50%':       { boxShadow: '0 0 28px rgba(212, 175, 55, 0.32)' },
        },
        fadeIn: {
          '0%':   { opacity: '0' },
          '100%': { opacity: '1' },
        },
        fadeInUp: {
          '0%':   { opacity: '0', transform: 'translateY(14px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        slideUp: {
          '0%':   { opacity: '0', transform: 'translateY(16px) scale(0.97)' },
          '100%': { opacity: '1', transform: 'translateY(0) scale(1)' },
        },
        glowBreathe: {
          '0%, 100%': { opacity: '0.4' },
          '50%':       { opacity: '0.8' },
        },
      },
    },
  },
  plugins: [],
}
