import {defineConfig} from 'vite';
export default defineConfig({
 server:{
  host:'0.0.0.0',
  port:5173,
  strictPort:true,
  proxy:{
   '/api':{target:'http://api:8080',changeOrigin:false},
   '/dev':{target:'http://api:8080',changeOrigin:false},
   '/auth':{target:'http://api:8080',changeOrigin:false}
  }
 }
});
