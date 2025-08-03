# TypaVibe - Mobile-First Collection Platform
*Built with Astro + Supabase + Netlify*

## Tech Stack
- **Frontend**: Astro (Static Site Generator + Server Rendering)
- **Backend**: Supabase (Database + Passwordless Auth + Storage)
- **Hosting**: Netlify (Edge Functions + Forms)
- **Monetization**: Skimlinks (Universal Affiliate Links)

---

## Phase 1: Project Setup & Foundation

### Step 1: Initialize Astro Project
```bash
# Create new Astro project
npm create astro@latest typavibe
cd typavibe

# Choose options:
# - Template: "Just the basics"  
# - TypeScript: No (keep it simple)
# - Install dependencies: Yes
```

### Step 2: Install Required Dependencies  
```bash
npm install @supabase/supabase-js
npm install @astrojs/netlify
```

### Step 3: Configure Astro for Hybrid Rendering
```javascript
// astro.config.mjs
import { defineConfig } from 'astro/config';
import netlify from '@astrojs/netlify/functions';

export default defineConfig({
  output: 'hybrid', // Static + server-rendered pages
  adapter: netlify(),
});
```

### Step 4: Project Structure
```
typavibe/
├── src/
│   ├── pages/
│   │   ├── index.astro              (homepage - static)
│   │   ├── create.astro             (create collection)
│   │   ├── explore.astro            (browse collections)
│   │   ├── auth.astro               (passwordless login)
│   │   └── [user]/
│   │       └── [collection].astro   (dynamic collection pages)
│   ├── components/
│   │   ├── CollectionCard.astro
│   │   ├── Header.astro
│   │   └── ItemCard.astro
│   ├── layouts/
│   │   └── Layout.astro
│   └── styles/
│       └── global.css
├── netlify.toml
├── .env
└── package.json
```

### Step 5: Setup Supabase Project
1. Create new Supabase project: "typavibe"
2. Create `.env` file:
```bash
# .env
PUBLIC_SUPABASE_URL=your_supabase_url
PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
```

---

## Phase 2: Database Schema Design

### Step 6: Create Supabase Tables

**Profiles Table** (extends Supabase Auth):
```sql
CREATE TABLE profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  username TEXT UNIQUE,
  display_name TEXT,
  bio TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);
```

**Collections Table**:
```sql
CREATE TABLE collections (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NULL, -- Allow null for anonymous
  title TEXT NOT NULL,
  description TEXT,
  slug TEXT UNIQUE NOT NULL,
  is_public BOOLEAN DEFAULT true,
  is_anonymous BOOLEAN DEFAULT false,
  anon_session_id TEXT, -- For anonymous collections  
  tags TEXT[] DEFAULT '{}',
  view_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  expires_at TIMESTAMP WITH TIME ZONE -- Optional: auto-delete anonymous after 30 days
);
```

**Collection Items Table**:
```sql
CREATE TABLE collection_items (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  collection_id UUID REFERENCES collections(id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  title TEXT,
  description TEXT,
  price DECIMAL(10,2),
  image_url TEXT,
  position INTEGER,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);
```

### Step 7: Enable Row Level Security (RLS)
```sql
-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE collection_items ENABLE ROW LEVEL SECURITY;

-- Collections policies
CREATE POLICY "Public collections are viewable by everyone"
ON collections FOR SELECT
USING (is_public = true);

CREATE POLICY "Users can view their own collections"
ON collections FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can create collections"
ON collections FOR INSERT
WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

CREATE POLICY "Users can update their own collections"
ON collections FOR UPDATE
USING (auth.uid() = user_id);

-- Collection items inherit collection permissions
CREATE POLICY "Items viewable if collection is viewable"
ON collection_items FOR SELECT
USING (
  collection_id IN (
    SELECT id FROM collections 
    WHERE is_public = true OR auth.uid() = user_id
  )
);
```

---

## Phase 3: Base Layout & Components

### Step 8: Create Base Layout
```astro
<!-- src/layouts/Layout.astro -->
---
export interface Props {
  title: string;
  description?: string;
}

const { title, description = "Create and share curated product collections" } = Astro.props;
---

<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="description" content={description} />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>{title}</title>
    
    <!-- Open Graph -->
    <meta property="og:title" content={title} />
    <meta property="og:description" content={description} />
    <meta property="og:type" content="website" />
    
    <!-- Skimlinks -->
    <script type="text/javascript">
      window.skimlinks_settings = {
        skimlinks_exclude: [],
        custom_css: false,
        link_store: 'your-store-id'
      };
    </script>
    <script src="//s.skimresources.com/js/xxxxx/skimlinks.js"></script>
  </head>
  <body>
    <slot />
  </body>
</html>
```

### Step 9: Create Supabase Client Utility
```javascript
// src/lib/supabase.js
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.PUBLIC_SUPABASE_URL
const supabaseAnonKey = import.meta.env.PUBLIC_SUPABASE_ANON_KEY

export const supabase = createClient(supabaseUrl, supabaseAnonKey)
```

---

## Phase 4: Core Pages Development

### Step 10: Homepage (Static)
```astro
<!-- src/pages/index.astro -->
---
import Layout from '../layouts/Layout.astro';
---

<Layout title="TypaVibe - Create collections in 30 seconds">
  <main>
    <section class="hero">
      <h1>Create a vibe in 30 seconds</h1>
      <p>No signup needed. Just start curating.</p>
      
      <!-- Quick create form -->
      <form action="/create" method="GET">
        <input 
          name="quick" 
          placeholder="What's your vibe?" 
          required 
        />
        <button type="submit">Create Collection</button>
      </form>
    </section>
    
    <!-- Featured collections will go here -->
  </main>
</Layout>
```

### Step 11: Collection Creation Page
```astro
<!-- src/pages/create.astro -->
---
import Layout from '../layouts/Layout.astro';
import { supabase } from '../lib/supabase.js';

// Handle form submission
if (Astro.request.method === 'POST') {
  const formData = await Astro.request.formData();
  const title = formData.get('title');
  const description = formData.get('description');
  
  // Create collection logic here
  // Redirect to collection page
}

const quickTitle = Astro.url.searchParams.get('quick') || '';
---

<Layout title="Create Collection - TypaVibe">
  <main>
    <form method="POST">
      <h1>Create Your Collection</h1>
      
      <input 
        name="title" 
        placeholder="Collection title" 
        value={quickTitle}
        required 
      />
      
      <textarea 
        name="description" 
        placeholder="What's this collection about?"
      ></textarea>
      
      <button type="submit">Create Collection</button>
    </form>
  </main>
</Layout>
```

### Step 12: Dynamic Collection Pages (Server-Rendered)
```astro
<!-- src/pages/[user]/[collection].astro -->
---
export const prerender = false; // Server-render this page

import Layout from '../../layouts/Layout.astro';
import { supabase } from '../../lib/supabase.js';

const { user, collection } = Astro.params;

// Fetch collection data
const { data: collectionData, error } = await supabase
  .from('collections')
  .select(`
    *,
    profiles(username, display_name),
    collection_items(*)
  `)
  .eq('slug', collection)
  .single();

if (error || !collectionData) {
  return new Response(null, { status: 404 });
}

// Increment view count
await supabase
  .from('collections')
  .update({ view_count: (collectionData.view_count || 0) + 1 })
  .eq('id', collectionData.id);

const title = `${collectionData.title} by ${collectionData.profiles?.display_name || 'Anonymous'}`;
---

<Layout title={title} description={collectionData.description}>
  <main>
    <header>
      <h1>{collectionData.title}</h1>
      <p>{collectionData.description}</p>
      <small>{collectionData.view_count} views</small>
    </header>
    
    <section class="items">
      {collectionData.collection_items.map(item => (
        <div class="item">
          <h3><a href={item.url} target="_blank">{item.title}</a></h3>
          <p>{item.description}</p>
          {item.price && <span class="price">${item.price}</span>}
        </div>
      ))}
    </section>
    
    <!-- Share buttons -->
    <button onclick="navigator.share({title: '{title}', url: window.location.href})">
      Share Collection
    </button>
  </main>
</Layout>
```

### Step 13: Explore Page (Server-Rendered)
```astro
<!-- src/pages/explore.astro -->
---
export const prerender = false;

import Layout from '../layouts/Layout.astro';
import { supabase } from '../lib/supabase.js';

// Fetch recent public collections
const { data: collections } = await supabase
  .from('collections')
  .select(`
    *,
    profiles(username, display_name)
  `)
  .eq('is_public', true)
  .order('created_at', { ascending: false })
  .limit(20);
---

<Layout title="Explore Collections - TypaVibe">
  <main>
    <h1>Explore Collections</h1>
    
    <section class="collections-grid">
      {collections?.map(collection => (
        <article class="collection-card">
          <h3>
            <a href={`/${collection.profiles?.username || 'anon'}/${collection.slug}`}>
              {collection.title}
            </a>
          </h3>
          <p>{collection.description}</p>
          <small>
            by {collection.profiles?.display_name || 'Anonymous'} • 
            {collection.view_count} views
          </small>
        </article>
      ))}
    </section>
  </main>
</Layout>
```

---

## Phase 5: Authentication System

### Step 14: Passwordless Auth Page
```astro
<!-- src/pages/auth.astro -->
---
import Layout from '../layouts/Layout.astro';
---

<Layout title="Sign In - TypaVibe">
  <main>
    <form id="auth-form">
      <h1>Sign in to save your collections</h1>
      
      <input 
        id="email" 
        type="email" 
        placeholder="Enter your email" 
        required 
      />
      
      <button type="submit">Send Magic Link</button>
    </form>
    
    <div id="otp-form" style="display:none;">
      <p>Check your email for the verification code</p>
      <input id="otp" placeholder="Enter 6-digit code" />
      <button id="verify-otp">Verify Code</button>
    </div>
  </main>

  <script>
    import { supabase } from '../lib/supabase.js';
    
    document.getElementById('auth-form').addEventListener('submit', async (e) => {
      e.preventDefault();
      const email = document.getElementById('email').value;
      
      const { error } = await supabase.auth.signInWithOtp({
        email: email,
        options: {
          shouldCreateUser: true
        }
      });
      
      if (!error) {
        document.getElementById('auth-form').style.display = 'none';
        document.getElementById('otp-form').style.display = 'block';
      }
    });
    
    document.getElementById('verify-otp').addEventListener('click', async () => {
      const email = document.getElementById('email').value;
      const token = document.getElementById('otp').value;
      
      const { error } = await supabase.auth.verifyOtp({
        email,
        token,
        type: 'email'
      });
      
      if (!error) {
        window.location.href = '/dashboard';
      }
    });
  </script>
</Layout>
```

---

## Phase 6: Mobile-First Styling

### Step 15: Claude/Notion-Inspired Styling
```css
/* src/styles/global.css */
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');

:root {
  --color-text: #1f2937;
  --color-text-secondary: #6b7280;
  --color-border: #e5e7eb;
  --color-border-hover: #d1d5db;
  --color-background: #ffffff;
  --color-background-secondary: #f9fafb;
  --color-accent: #2563eb;
  --color-accent-hover: #1d4ed8;
  --shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
  --shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
  --radius: 12px;
  --radius-sm: 8px;
}

* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

body {
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  line-height: 1.6;
  color: var(--color-text);
  background: var(--color-background);
  font-size: 15px;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

/* Layout */
main {
  max-width: 100%;
  margin: 0 auto;
  padding: 24px 16px;
}

@media (min-width: 768px) {
  main {
    max-width: 768px;
    padding: 48px 24px;
  }
}

@media (min-width: 1024px) {
  main {
    max-width: 896px;
  }
}

/* Typography - Notion style */
h1 {
  font-size: 2rem;
  font-weight: 700;
  line-height: 1.2;
  margin-bottom: 16px;
  color: var(--color-text);
}

h2 {
  font-size: 1.5rem;
  font-weight: 600;
  line-height: 1.3;
  margin-bottom: 12px;
  color: var(--color-text);
}

h3 {
  font-size: 1.125rem;
  font-weight: 600;
  line-height: 1.4;
  margin-bottom: 8px;
  color: var(--color-text);
}

p {
  color: var(--color-text-secondary);
  margin-bottom: 16px;
}

/* Forms - Claude inspired */
form {
  display: flex;
  flex-direction: column;
  gap: 20px;
  max-width: 480px;
}

input, textarea {
  padding: 12px 16px;
  font-size: 15px;
  border: 1.5px solid var(--color-border);
  border-radius: var(--radius-sm);
  background: var(--color-background);
  transition: all 0.2s ease;
  font-family: inherit;
  min-height: 44px;
  resize: vertical;
}

input:focus, textarea:focus {
  outline: none;
  border-color: var(--color-accent);
  box-shadow: 0 0 0 3px rgb(37 99 235 / 0.1);
}

input::placeholder, textarea::placeholder {
  color: var(--color-text-secondary);
}

textarea {
  min-height: 120px;
  line-height: 1.5;
}

/* Buttons - Claude style */
button {
  padding: 12px 24px;
  font-size: 15px;
  font-weight: 500;
  border: none;
  border-radius: var(--radius-sm);
  cursor: pointer;
  transition: all 0.2s ease;
  font-family: inherit;
  min-height: 44px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

.btn-primary {
  background: var(--color-accent);
  color: white;
}

.btn-primary:hover {
  background: var(--color-accent-hover);
  transform: translateY(-1px);
  box-shadow: var(--shadow-md);
}

.btn-secondary {
  background: var(--color-background-secondary);
  color: var(--color-text);
  border: 1.5px solid var(--color-border);
}

.btn-secondary:hover {
  border-color: var(--color-border-hover);
  background: white;
}

/* Cards - Notion inspired */
.collection-card {
  background: var(--color-background);
  border: 1.5px solid var(--color-border);
  border-radius: var(--radius);
  padding: 24px;
  transition: all 0.2s ease;
  cursor: pointer;
}

.collection-card:hover {
  border-color: var(--color-border-hover);
  box-shadow: var(--shadow-md);
  transform: translateY(-2px);
}

.collection-card h3 {
  margin-bottom: 8px;
}

.collection-card h3 a {
  text-decoration: none;
  color: var(--color-text);
  font-weight: 600;
}

.collection-card p {
  color: var(--color-text-secondary);
  font-size: 14px;
  margin-bottom: 12px;
  line-height: 1.5;
}

.collection-card small {
  color: var(--color-text-secondary);
  font-size: 13px;
  font-weight: 500;
}

/* Collection grid */
.collections-grid {
  display: grid;
  gap: 20px;
  grid-template-columns: 1fr;
}

@media (min-width: 768px) {
  .collections-grid {
    grid-template-columns: repeat(2, 1fr);
    gap: 24px;
  }
}

@media (min-width: 1024px) {
  .collections-grid {
    grid-template-columns: repeat(3, 1fr);
  }
}

/* Hero section */
.hero {
  text-align: center;
  max-width: 600px;
  margin: 0 auto 64px;
}

.hero h1 {
  font-size: 2.5rem;
  font-weight: 700;
  margin-bottom: 16px;
  background: linear-gradient(135deg, var(--color-text) 0%, var(--color-text-secondary) 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

@media (min-width: 768px) {
  .hero h1 {
    font-size: 3rem;
  }
}

.hero p {
  font-size: 1.125rem;
  color: var(--color-text-secondary);
  margin-bottom: 32px;
}

/* Items list */
.items {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.item {
  background: var(--color-background-secondary);
  border: 1.5px solid var(--color-border);
  border-radius: var(--radius-sm);
  padding: 20px;
  transition: all 0.2s ease;
}

.item:hover {
  border-color: var(--color-border-hover);
  background: white;
}

.item h3 a {
  color: var(--color-accent);
  text-decoration: none;
  font-weight: 600;
}

.item h3 a:hover {
  text-decoration: underline;
}

.item .price {
  display: inline-block;
  background: var(--color-accent);
  color: white;
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 13px;
  font-weight: 600;
  margin-top: 8px;
}

/* Responsive utilities */
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}

/* Loading states */
.loading {
  opacity: 0.6;
  pointer-events: none;
}

/* Smooth focus styles throughout */
*:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}
```

---

## Phase 7: Netlify Configuration

### Step 16: Netlify Configuration
```toml
# netlify.toml
[build]
  command = "npm run build"
  publish = "dist"

[[headers]]
  for = "/api/*"
  [headers.values]
    Access-Control-Allow-Origin = "*"
    Access-Control-Allow-Methods = "GET, POST, PUT, DELETE, OPTIONS"
    Access-Control-Allow-Headers = "Content-Type, Authorization"

[functions]
  directory = "netlify/functions"
```

### Step 17: Environment Variables in Netlify
Set these in Netlify dashboard:
- `PUBLIC_SUPABASE_URL`
- `PUBLIC_SUPABASE_ANON_KEY`

---

## Phase 8: Advanced Features

### Step 18: Anonymous Collection Support
Add localStorage-based anonymous session tracking for collection ownership before signup.

### Step 19: Collection Item Management
Add drag-and-drop item reordering and item editing capabilities.

### Step 20: Social Sharing
Implement native Web Share API with fallback to copy-link functionality.

### Step 21: Search and Tags
Add tag-based browsing and collection search functionality.

---

## Phase 9: Launch Preparation

### Step 22: SEO Optimization
- Dynamic meta tags for all collection pages
- Sitemap generation
- Schema.org markup for collections

### Step 23: Performance Optimization
- Image lazy loading
- Critical CSS inlining
- Service worker for offline capability

### Step 24: Analytics Integration
- Google Analytics 4
- Supabase analytics for collection metrics
- Click tracking for affiliate links

---

## Deployment Steps

1. **Push to GitHub**
2. **Connect to Netlify**
3. **Set environment variables**
4. **Deploy!**

Your collection URLs will automatically work:
- `typavibe.com/john/summer-essentials` ✨
- `typavibe.com/anon/cozy-night-vibes` ✨

---

## Key Benefits of This Approach

- **Lightning fast**: Static homepage, server-rendered collections
- **SEO perfect**: Real-time meta tags, instant indexing
- **Zero config**: File-based routing, automatic optimization  
- **Mobile first**: Touch-friendly, PWA-ready
- **Simple maintenance**: Minimal complexity, maximum results

Ready to build! 🚀