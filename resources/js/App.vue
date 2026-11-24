<template>
  <router-view />
</template>

<script setup>
import { useDark } from '@vueuse/core';

useDark();
</script>
