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

describe('ThemeToggle', () => {
  beforeEach(() => {
    localStorageMock.getItem.mockClear()
    localStorageMock.setItem.mockClear()
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
})
