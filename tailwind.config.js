const brand = {
  25: '#f2f7ff',
  50: '#ecf3ff',
  100: '#dde9ff',
  200: '#c2d6ff',
  300: '#9cb9ff',
  400: '#7592ff',
  500: '#465fff',
  600: '#3641f5',
  700: '#2a31d8',
  800: '#252dae',
  900: '#262e89',
  950: '#161950',
};

module.exports = {
  darkMode: 'class',
  content: ['./resources/**/*.blade.php', './resources/**/*.js', './resources/**/*.vue'],
  theme: {
    extend: {
      fontFamily: {
        outfit: ['Outfit', 'system-ui', 'sans-serif'],
      },
      fontSize: {
        'title-sm': ['30px', '38px'],
        'theme-sm': ['14px', '20px'],
        'theme-xs': ['12px', '18px'],
      },
      maxWidth: {
        'breakpoint-2xl': '1536px',
      },
      colors: {
        brand,
        success: {
          50: '#ecfdf3',
          500: '#12b76a',
          700: '#027a48',
        },
        warning: {
          50: '#fffaeb',
          400: '#fdb022',
          700: '#b54708',
        },
        error: {
          50: '#fef3f2',
          500: '#f04438',
          700: '#b42318',
        },
      },
      boxShadow: {
        'theme-md': '0px 4px 8px -2px rgba(16, 24, 40, 0.1), 0px 2px 4px -2px rgba(16, 24, 40, 0.06)',
      },
    },
  },
  plugins: [],
};
