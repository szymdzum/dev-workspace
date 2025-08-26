import type { Meta, StoryObj } from '@storybook/react'

// Since this is an Astro component, we can't render it directly in Storybook
// But we can document it and provide usage examples

const meta: Meta = {
  title: 'Astro Components/Header',
  parameters: {
    docs: {
      description: {
        component: `
# Header Component

The Header component is an Astro component that provides a flexible page header with title and optional subtitle.

## Props
- \`title\` (string, required): The main title text to display
- \`subtitle\` (string, optional): Optional subtitle text displayed below the title

## Usage

Since this is an Astro component, it's used differently than React components. Here's how to import and use it in your Astro pages:

\`\`\`astro
---
import Header from '@library/ui/astro/Header.astro';
---

<Header title="Welcome" subtitle="To our amazing site" />
\`\`\`

## Examples

### Basic Header
\`\`\`astro
<Header title="My Page" />
\`\`\`

### Header with Subtitle
\`\`\`astro
<Header title="Documentation" subtitle="Learn how to use our components" />
\`\`\`

## Implementation

The component uses scoped Astro styles and is designed to be flexible. You can test it in the playground app at http://localhost:4321
        `,
      },
    },
  },
  tags: ['autodocs'],
}

export default meta

// We can't actually render Astro components in Storybook, so we provide documentation only
export const Documentation: StoryObj = {
  render: () => {
    return (
      <div
        style={{
          padding: '2rem',
          border: '2px dashed #ccc',
          borderRadius: '8px',
          textAlign: 'center',
          backgroundColor: '#f9f9f9',
        }}
      >
        <h2>🚀 Astro Component</h2>
        <p>This is an Astro component that can't be rendered directly in Storybook.</p>
        <p>
          <strong>To see it in action:</strong>
        </p>
        <p>
          Visit the playground at{' '}
          <a href="http://localhost:4321" target="_blank" rel="noopener">
            http://localhost:4321
          </a>
        </p>
        <br />
        <code
          style={{
            backgroundColor: '#fff',
            padding: '0.5rem',
            borderRadius: '4px',
            display: 'inline-block',
          }}
        >
          import Header from '@library/ui/astro/Header.astro';
        </code>
      </div>
    )
  },
}
