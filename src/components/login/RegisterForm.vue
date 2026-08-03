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
        placeholder="设置登录密码（≥6 位）"
        maxlength="32"
        show-password
        clearable
      />
    </el-form-item>
    <el-form-item label="昵称（可选）" prop="displayName">
      <el-input v-model="form.displayName" placeholder="留空将使用默认昵称" maxlength="32" clearable />
    </el-form-item>
    <el-form-item>
      <el-button
        type="primary"
        :loading="loading"
        style="width: 100%"
        @click="onSubmit"
      >注册并登录</el-button>
    </el-form-item>
  </el-form>
</template>

<script>
export default {
  name: 'RegisterForm',
  data () {
    return {
      loading: false,
      form: { phone: '', password: '', displayName: '' },
      rules: {
        phone: [
          { required: true, message: '请输入手机号', trigger: 'blur' },
          { pattern: /^1[3-9]\d{9}$/, message: '请输入有效的 11 位手机号', trigger: 'blur' }
        ],
        password: [
          { required: true, message: '请设置密码', trigger: 'blur' },
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
          await this.$store.dispatch('user/register', {
            phone: this.form.phone,
            password: this.form.password,
            displayName: this.form.displayName || undefined
          })
          this.$message.success('注册成功')
          this.$emit('success')
        } catch (e) {
          this.$message.error(e.message || '注册失败')
        } finally {
          this.loading = false
        }
      })
    }
  }
}
</script>
