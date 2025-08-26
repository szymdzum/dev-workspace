import React from 'react'
import { fireEvent, render, screen } from '@testing-library/react'
import { ThemeToggle } from './ThemeToggle'

// Mock localStorage
const localStorageMock = {
  getItem: vi.fn(),
  setItem: vi.fn(),
  removeItem: vi.fn(),
  clear: vi.fn(),
}

Object.defineProperty(window, 'localStorage', {
  value: localStorageMock,
})

// Mock document.documentElement for DOM manipulation
const documentElementMock = {
  setAttribute: vi.fn(),
  removeAttribute: vi.fn(),
}

Object.defineProperty(document, 'documentElement', {
  value: documentElementMock,
  configurable: true,
})

describe('ThemeToggle', () => {
  beforeEach(() => {
    localStorageMock.getItem.mockClear()
    localStorageMock.setItem.mockClear()
    documentElementMock.setAttribute.mockClear()
    documentElementMock.removeAttribute.mockClear()
  })

  it('renders with default light theme', () => {
    localStorageMock.getItem.mockReturnValue(null)

    render(<ThemeToggle />)

    const button = screen.getByRole('button', { name: /toggle theme/i })
    expect(button).toBeInTheDocument()
    expect(button).toHaveTextContent('☀️')
  })

  it('renders with dark theme when stored in localStorage', () => {
    localStorageMock.getItem.mockReturnValue('dark')

    render(<ThemeToggle />)

    const button = screen.getByRole('button', { name: /toggle theme/i })
    expect(button).toHaveTextContent('🌙')
  })

  it('toggles theme when clicked', () => {
    localStorageMock.getItem.mockReturnValue(null)

    render(<ThemeToggle />)

    const button = screen.getByRole('button', { name: /toggle theme/i })

    // Should start with sun (light mode)
    expect(button).toHaveTextContent('☀️')

    // Click to toggle to dark mode
    fireEvent.click(button)

    // Should now show moon (dark mode)
    expect(button).toHaveTextContent('🌙')
    expect(localStorageMock.setItem).toHaveBeenCalledWith('theme', 'dark')
  })

  it('applies custom className', () => {
    render(<ThemeToggle className="custom-class" />)

    const button = screen.getByRole('button', { name: /toggle theme/i })
    expect(button).toHaveClass('custom-class')
  })

  it('applies theme to document element', () => {
    localStorageMock.getItem.mockReturnValue('dark')

    render(<ThemeToggle />)

    // Should set data-theme attribute for dark theme
    expect(documentElementMock.setAttribute).toHaveBeenCalledWith('data-theme', 'dark')
  })

  it('removes theme attribute when switching to light mode', () => {
    localStorageMock.getItem.mockReturnValue('dark')

    render(<ThemeToggle />)

    const button = screen.getByRole('button', { name: /toggle theme/i })

    // Click to toggle to light mode
    fireEvent.click(button)

    // Should remove data-theme attribute for light mode
    expect(documentElementMock.removeAttribute).toHaveBeenCalledWith('data-theme')
    expect(localStorageMock.setItem).toHaveBeenCalledWith('theme', 'light')
  })
})
