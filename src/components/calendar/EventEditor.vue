<template>
  <div class="event-editor">
    <header class="ee-head">
      <h3>{{ isEdit ? '编辑事件' : '新建事件' }}</h3>
      <button class="ee-close" @click="$emit('close')">×</button>
    </header>
    <div class="ee-body">
      <div class="ee-field">
        <label>标题</label>
        <input v-model="form.title" placeholder="输入事件标题" class="ee-input" />
      </div>
      <div class="ee-field">
        <label>全天</label>
        <van-switch v-model="form.allDay" size="20px" />
      </div>
      <div class="ee-field">
        <label>开始时间</label>
        <input
          :type="form.allDay ? 'date' : 'datetime-local'"
          v-model="startDate"
          class="ee-input"
          @change="onStartChange"
        />
      </div>
      <div v-if="!form.allDay" class="ee-field">
        <label>时长（分钟）</label>
        <input v-model.number="form.duration" type="number" class="ee-input" min="15" step="15" />
      </div>
      <div v-if="!form.allDay" class="ee-field">
        <label>结束时间</label>
        <input type="datetime-local" :value="endDate" disabled class="ee-input ee-disabled" />
      </div>
      <div class="ee-field">
        <label>类型</label>
        <div class="ee-type-group">
          <button
            v-for="t in types"
            :key="t.key"
            :class="['ee-type-btn', { active: form.type === t.key }]"
            @click="form.type = t.key"
          >{{ t.label }}</button>
        </div>
      </div>
      <div class="ee-field">
        <label>颜色</label>
        <div class="ee-color-group">
          <button
            v-for="c in colors"
            :key="c"
            :class="['ee-color-btn', { active: form.color === c }]"
            :style="{ background: c }"
            @click="form.color = c"
          ></button>
        </div>
      </div>
      <div class="ee-field">
        <label>地点</label>
        <input v-model="form.location" placeholder="输入地点（可选）" class="ee-input" />
      </div>
      <div class="ee-field">
        <label>描述</label>
        <textarea v-model="form.description" placeholder="输入描述（可选）" class="ee-textarea" rows="3"></textarea>
      </div>
    </div>
    <footer class="ee-footer">
      <button v-if="isEdit" class="ee-btn ee-btn-danger" @click="$emit('delete', form.id)">删除</button>
      <button class="ee-btn ee-btn-cancel" @click="$emit('close')">取消</button>
      <button class="ee-btn ee-btn-save" @click="onSave">保存</button>
    </footer>
  </div>
</template>

<script>
export default {
  name: 'EventEditor',
  props: {
    event: { type: Object, default: null }
  },
  data () {
    return {
      form: {
        id: null,
        title: '',
        date: Date.now(),
        duration: 60,
        allDay: false,
        color: '#6366f1',
        type: 'work',
        location: '',
        description: '',
        source: 'local'
      },
      types: [
        { key: 'work', label: '工作' },
        { key: 'life', label: '生活' },
        { key: 'health', label: '健康' },
        { key: 'study', label: '学习' }
      ],
      colors: ['#6366f1', '#a855f7', '#ec4899', '#ef4444', '#f59e0b', '#10b981', '#3b82f6', '#6b7280']
    }
  },
  computed: {
    isEdit () {
      return !!this.form.id
    },
    startDate: {
      get () {
        const d = new Date(this.form.date)
        if (this.form.allDay) {
          return d.toISOString().split('T')[0]
        }
        return this.toLocalDatetimeString(d)
      },
      set (val) {
        this.form.date = new Date(val).getTime()
      }
    },
    endDate () {
      const d = new Date(this.form.date + this.form.duration * 60000)
      return this.toLocalDatetimeString(d)
    }
  },
  created () {
    if (this.event) {
      this.form = { ...this.event }
    }
  },
  methods: {
    toLocalDatetimeString (date) {
      const y = date.getFullYear()
      const m = String(date.getMonth() + 1).padStart(2, '0')
      const d = String(date.getDate()).padStart(2, '0')
      const h = String(date.getHours()).padStart(2, '0')
      const min = String(date.getMinutes()).padStart(2, '0')
      return `${y}-${m}-${d}T${h}:${min}`
    },
    onStartChange () {
      // 确保日期已更新
    },
    onSave () {
      if (!this.form.title.trim()) {
        alert('请输入标题')
        return
      }
      this.$emit('save', { ...this.form })
    }
  }
}
</script>

<style scoped>
.event-editor {
  padding: 16px;
}
.ee-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 16px;
}
.ee-head h3 {
  margin: 0;
  font-size: 16px;
  font-weight: 600;
}
.ee-close {
  background: transparent;
  border: none;
  font-size: 24px;
  color: var(--text-muted);
}
.ee-body {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.ee-field {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.ee-field label {
  font-size: 13px;
  color: var(--text-secondary);
  font-weight: 500;
}
.ee-input {
  padding: 8px 12px;
  border: 1px solid var(--border);
  border-radius: 6px;
  background: var(--bg-secondary);
  color: var(--text-primary);
  font-size: 14px;
}
.ee-input.ee-disabled {
  opacity: 0.6;
}
.ee-textarea {
  padding: 8px 12px;
  border: 1px solid var(--border);
  border-radius: 6px;
  background: var(--bg-secondary);
  color: var(--text-primary);
  font-size: 14px;
  resize: vertical;
}
.ee-type-group {
  display: flex;
  gap: 8px;
}
.ee-type-btn {
  flex: 1;
  padding: 8px;
  border: 1px solid var(--border);
  border-radius: 6px;
  background: var(--bg-secondary);
  color: var(--text-primary);
  font-size: 13px;
}
.ee-type-btn.active {
  background: var(--accent);
  color: #fff;
  border-color: var(--accent);
}
.ee-color-group {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}
.ee-color-btn {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  border: 2px solid transparent;
}
.ee-color-btn.active {
  border-color: var(--text-primary);
  box-shadow: 0 0 0 2px var(--bg-primary);
}
.ee-footer {
  display: flex;
  gap: 8px;
  margin-top: 16px;
  padding-top: 16px;
  border-top: 1px solid var(--border);
}
.ee-btn {
  flex: 1;
  padding: 10px;
  border: none;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 500;
}
.ee-btn-danger {
  background: #ef4444;
  color: #fff;
}
.ee-btn-cancel {
  background: var(--bg-secondary);
  color: var(--text-primary);
}
.ee-btn-save {
  background: var(--accent);
  color: #fff;
}
</style>