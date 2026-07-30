<template>
  <div data-theme-wrap>
    <slot />
  </div>
</template>

<script>
export default {
  name: 'ThemeProvider',
  watch: {
    '$store.state.settings.theme': {
      immediate: true,
      handler (v) {
        if (v) document.documentElement.setAttribute('data-theme', v)
      }
    }
  }
}
</script>
