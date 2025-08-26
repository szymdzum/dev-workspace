import type React from 'react'
import { useEffect, useState } from 'react'

export interface ThemeToggleProps {
  className?: string
}

export const ThemeToggle: React.FC<ThemeToggleProps> = ({ className }) => {
  // Initialize theme state synchronously to avoid race conditions
  const [isDark, setIsDark] = useState(() => {
    // Safe access to localStorage and window with fallbacks for SSR/testing
    try {
      const savedTheme = typeof localStorage !== 'undefined' ? localStorage.getItem('theme') : null
      const prefersDark =
        typeof window !== 'undefined' && window.matchMedia
          ? window.matchMedia('(prefers-color-scheme: dark)').matches
          : false

      return savedTheme === 'dark' || (!savedTheme && prefersDark)
    } catch (_error) {
      // Fallback for environments where localStorage or matchMedia are not available
      return false
    }
  })

  useEffect(() => {
    // Apply the theme to the document only after component mounts
    if (isDark) {
      document.documentElement.setAttribute('data-theme', 'dark')
    } else {
      document.documentElement.removeAttribute('data-theme')
    }
  }, [isDark])

  const toggleTheme = () => {
    const newTheme = !isDark
    setIsDark(newTheme)

    if (newTheme) {
      document.documentElement.setAttribute('data-theme', 'dark')
      localStorage.setItem('theme', 'dark')
    } else {
      document.documentElement.removeAttribute('data-theme')
      localStorage.setItem('theme', 'light')
    }
  }

  return (
    <button
      type="button"
      onClick={toggleTheme}
      className={`theme-toggle ${className || ''}`}
      aria-label="Toggle theme"
    >
      {isDark ? '🌙' : '☀️'}
    </button>
  )
}

export default ThemeToggle
