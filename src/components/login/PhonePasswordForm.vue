<template>
  <el-form
    ref="form"
    :model="form"
    :rules="rules"
    size="medium"
    label-position="top"
    @submit.native.prevent="onSubmit"
  >
    <el-form-item label="手机号" prop="phone">
      <el-input v-model="form.phone" placeholder="请输入 11 位手机号" maxlength="11" clearable />
    </el-form-item>
    <el-form-item label="密码" prop="password">
      <el-input
        v-model="form.password"
        type="password"
        placeholder="请输入密码（≥6 位）"
        maxlength="32"
        show-password
        clearable
      />
    </el-form-item>
    <el-form-item>
      <el-button
        type="primary"
        :loading="loading"
        style="width: 100%"
        @click="onSubmit"
      >登录</el-button>
    </el-form-item>
  </el-form>
</template>

<script>
export default {
  name: 'PhonePasswordForm',
  data () {
    return {
      loading: false,
      form: { phone: '', password: '' },
      rules: {
        phone: [
          { required: true, message: '请输入手机号', trigger: 'blur' },
          { pattern: /^1[3-9]\d{9}$/, message: '请输入有效的 11 位手机号', trigger: 'blur' }
        ],
        password: [
          { required: true, message: '请输入密码', trigger: 'blur' },
          { min: 6, message: '密码至少 6 位', trigger: 'blur' }
        ]
      }
    }
  },
  methods: {
    onSubmit () {
      this.$refs.form.validate(async valid => {
        if (!valid) return
        this.loading = true
        try {
          await this.$store.dispatch('user/login', { phone: this.form.phone, password: this.form.password })
          this.$message.success('登录成功')
          this.$emit('success')
        } catch (e) {
          this.$message.error(e.message || '登录失败')
        } finally {
          this.loading = false
        }
      })
    }
  }
}
</script>
