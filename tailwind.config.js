/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{vue,js,ts,jsx,tsx}"],
  theme: {
    extend: {
      colors: {
        nibbles: {
          red: '#C0392B',
          'red-dark': '#A93226',
          cream: '#FDF6EC',
          brown: '#6B3F1F',
          dark: '#1A1A1A',
        }
      },
      fontFamily: { 
        sans: ['Inter', 'system-ui', 'sans-serif'],
        heading: ['Inter', 'system-ui', 'sans-serif']
      },
      letterSpacing: {
        tight: '-0.01em',
        normal: '0em',
        wide: '0.025em'
      }
    },
  },
  plugins: [],
}
