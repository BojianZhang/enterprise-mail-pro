import request from '@/utils/request'

export const downloadAttachment = (id: number) => {
  return request.get(`/attachments/${id}/download`, {
    responseType: 'blob'
  })
}

export const viewAttachment = (id: number) => {
  return request.get(`/attachments/${id}/view`)
}

export const deleteAttachment = (id: number) => {
  return request.delete(`/attachments/${id}`)
}

export const getAttachmentInfo = (id: number) => {
  return request.get(`/attachments/${id}`)
}

export const uploadAttachment = (file: File, emailId?: number) => {
  const formData = new FormData()
  formData.append('file', file)
  if (emailId) {
    formData.append('emailId', emailId.toString())
  }
  
  return request.post('/attachments/upload', formData, {
    headers: { 'Content-Type': 'multipart/form-data' },
    onUploadProgress: (progressEvent) => {
      const percentCompleted = Math.round((progressEvent.loaded * 100) / (progressEvent.total || 1))
      // You can handle progress here if needed
      console.log(`Upload Progress: ${percentCompleted}%`)
    }
  })
}

export const uploadMultipleAttachments = (files: FileList, emailId?: number) => {
  const formData = new FormData()
  Array.from(files).forEach(file => {
    formData.append('files', file)
  })
  if (emailId) {
    formData.append('emailId', emailId.toString())
  }
  
  return request.post('/attachments/upload-multiple', formData, {
    headers: { 'Content-Type': 'multipart/form-data' }
  })
}

export const getAttachmentPreview = (id: number) => {
  return request.get(`/attachments/${id}/preview`)
}

export const getAttachmentsByEmail = (emailId: number) => {
  return request.get(`/attachments/email/${emailId}`)
}

export const scanAttachmentForVirus = (id: number) => {
  return request.post(`/attachments/${id}/scan`)
}

export const validateAttachment = (file: File) => {
  const formData = new FormData()
  formData.append('file', file)
  
  return request.post('/attachments/validate', formData, {
    headers: { 'Content-Type': 'multipart/form-data' }
  })
}