import { createApp } from 'vue';
import Alpine from 'alpinejs';
import App from './App.vue';
import router from './router';
import './bootstrap';
import 'tom-select/dist/css/tom-select.css';

window.Alpine = Alpine;
Alpine.start();

createApp(App).use(router).mount('#app');
