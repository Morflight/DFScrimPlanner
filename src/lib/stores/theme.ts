import { writable } from 'svelte/store';
import { browser } from '$app/environment';

function createThemeStore() {
	const stored = browser ? localStorage.getItem('theme') : null;
	const prefersDark = browser ? window.matchMedia('(prefers-color-scheme: dark)').matches : false;
	const initial: 'light' | 'dark' = stored === 'dark' || stored === 'light'
		? stored
		: prefersDark ? 'dark' : 'light';

	const { subscribe, set, update } = writable<'light' | 'dark'>(initial);

	return {
		subscribe,
		toggle() {
			update((current) => {
				const next = current === 'dark' ? 'light' : 'dark';
				if (browser) {
					localStorage.setItem('theme', next);
					document.documentElement.classList.toggle('dark', next === 'dark');
				}
				return next;
			});
		}
	};
}

export const theme = createThemeStore();
