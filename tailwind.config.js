/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{vue,js,ts,jsx,tsx}"],
  theme: {
    extend: {
      colors: {
        // Brand — a warm, deep brick/terracotta (artisan, not primary-red)
        brand: {
          50: '#FBF1EF',
          100: '#F6E0DB',
          200: '#EDC1B8',
          300: '#E09C90',
          400: '#D17263',
          500: '#BB4B39',
          600: '#A23A2B',
          700: '#84301F',
          800: '#6B2A1E',
          900: '#4F2017',
        },
        // Warm cream surfaces
        cream: {
          DEFAULT: '#FBF7F0',
          50: '#FDFBF7',
          100: '#FBF7F0',
          200: '#F4EADB',
          300: '#EADCC6',
        },
        // Warm near-black + muted text tones
        ink: {
          DEFAULT: '#1C1917',
          soft: '#44403C',
          muted: '#78716C',
        },
        // Back-compat aliases so existing markup picks up the refreshed palette
        nibbles: {
          red: '#A23A2B',
          'red-dark': '#84301F',
          cream: '#FBF7F0',
          brown: '#6B3F1F',
          dark: '#1C1917',
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        display: ['Syne', 'Inter', 'system-ui', 'sans-serif'],
        heading: ['Syne', 'Inter', 'system-ui', 'sans-serif'],
      },
      letterSpacing: {
        tight: '-0.015em',
        normal: '0em',
        wide: '0.04em',
      },
      borderRadius: {
        xl: '0.875rem',
        '2xl': '1.125rem',
      },
      boxShadow: {
        card: '0 1px 2px rgba(28,25,23,0.04), 0 6px 20px rgba(28,25,23,0.06)',
        'card-hover': '0 12px 30px rgba(162,58,43,0.12)',
        soft: '0 20px 60px rgba(28,25,23,0.12)',
      },
    },
  },
  plugins: [],
}
