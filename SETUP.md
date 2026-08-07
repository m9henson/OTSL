# Ozark Travel Stein League — Supabase Setup

## 1. Create the Supabase project
1. Go to Supabase and create a Free project.
2. Save the database password somewhere private.
3. Wait until the project is ready.

## 2. Create the database and security rules
1. Open **SQL Editor** in the Supabase dashboard.
2. Choose **New query**.
3. Open `schema.sql` from this package and copy all of it.
4. Paste it into SQL Editor and press **Run**.
5. A successful run creates the tables, functions, Row Level Security policies, and Realtime publication.

## 3. Configure Authentication
1. Open **Authentication → Providers**.
2. Keep **Email** enabled.
3. Turn **Confirm email** OFF. This is necessary because the app internally converts the username to a private placeholder email.
4. Open **Authentication → Settings** and enable **Anonymous Sign-Ins**.
5. In **URL Configuration**, set the Site URL to `https://m9henson.github.io/`.

## 4. Copy the browser-safe project values
1. Open **Project Settings → Data API** (or API Keys, depending on dashboard layout).
2. Copy the **Project URL**.
3. Copy the **publishable key** or legacy **anon public** key. Never use the service-role/secret key in GitHub.
4. Open `supabase-config.js` and replace both placeholders.

## 5. Upload to GitHub Pages
Delete the old Firebase website files. Upload these files directly to the repository root:
- `index.html`
- `app.js`
- `styles.css`
- `supabase-config.js`
- `manifest.webmanifest`
- `service-worker.js`

Commit and wait for GitHub Pages to deploy.

## 6. Create the administrator
1. Open `https://m9henson.github.io/?supabase=1`.
2. Enter a username and a password of at least 6 characters.
3. Tap **Create First Admin Account** once.
4. Future visits use **Sign In**.

The app internally converts username `m9henson` to `m9henson@ozarktravelstein.app`; you never need to use that email in the app.

## 7. Create and configure a tournament
1. Tap **New Tournament**.
2. Enter name, course, date, and 9 or 18 holes.
3. Add players and assign Group 1–6.
4. Open Setup, select handicap/blind skin holes, and mark the tournament active.
5. Tap **Generate New Links** and send each group only its own link.

Permanent spectator link: `https://m9henson.github.io/?spectator=1`

## 8. Test security
1. Open Group 1's link in a Private Browsing tab.
2. Confirm only Group 1 is selectable.
3. Save a Group 1 score.
4. Do not test links in the same regular Safari tab as the administrator, because the saved admin session can affect what the screen displays.
