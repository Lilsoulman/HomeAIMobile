<template>
  <header class="app-header">
    <div class="app-header-inner">
      <div class="brand">
        <span class="brand-dot" />
        <span class="brand-name">HomeMind</span>
      </div>
      <div class="header-right">
        <button class="icon-btn" @click="$router.push('/me')" aria-label="设置">
          <van-icon name="setting-o" size="20" />
        </button>
      </div>
    </div>
  </header>
</template>

<script>
export default { name: 'AppHeader' }
</script>

<style scoped>
.app-header {
  position: sticky;
  top: 0;
  z-index: 10;
  background: linear-gradient(180deg, var(--bg-primary) 70%, transparent);
  padding-top: env(safe-area-inset-top);
}
.app-header-inner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: 44px;
  padding: 0 16px;
}
.brand { display: flex; align-items: center; gap: 8px; }
.brand-dot {
  width: 8px; height: 8px; border-radius: 50%;
  background: var(--accent);
  box-shadow: 0 0 8px var(--accent-glow);
}
.brand-name { font-size: 16px; font-weight: 600; letter-spacing: 0.5px; }
.icon-btn {
  width: 32px; height: 32px;
  display: flex; align-items: center; justify-content: center;
  background: transparent; border: 0; color: var(--text-secondary);
}
</style>