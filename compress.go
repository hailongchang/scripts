package main

import (
	"archive/tar"
	"compress/gzip"
	"errors"
	"io"
	"log"
	"os"
	"path/filepath"
	"strings"
)

func getCurrentDirectory() string {
	dir, err := filepath.Abs(filepath.Dir(os.Args[0]))
	if err != nil {
		log.Fatal(err)
	}
	return strings.Replace(dir, "\\", "/", -1)
}

func getcfs(pwd string) ([]*os.File, error) {

	var files []*os.File = make([]*os.File, 0, 1024)
	filepath.Walk(pwd, func(path string, info os.FileInfo, err error) error {
		fc, ferr := os.Open(path)
		if ferr != nil {
			log.Printf("getzpath: %s\n", ferr)
			return ferr
		}
		log.Println(path, "has been added.")
		files = append(files, fc)
		if info.IsDir() == true {
			var SkipDir = errors.New("skip this directory")
			return SkipDir
		} else {
			return nil
		}
	})
	return files, nil
}

func main() {
	pwd := getCurrentDirectory()
	zipfile := pwd + "/test_go_compress.tar.gz"
	fs, err := getcfs(pwd + "/src")
	if err != nil {
		log.Printf("get file map error: %s", err)
		return
	}
	if err = Compress(fs, zipfile); err != nil {
		log.Printf("output zip: %s\n", err)
		return
	}
}

// 目录压缩过程
func Compress(files []*os.File, dest string) error {
	d, _ := os.Create(dest)
	defer d.Close()
	gw := gzip.NewWriter(d)
	defer gw.Close()
	tw := tar.NewWriter(gw)
	defer tw.Close()
	for _, file := range files {
		err := compressfile(file, "", tw)
		if err != nil {
			log.Printf("Compress: %s\n", err)
			return err
		}
	}
	return nil
}

// // 压缩文件
func compressfile(file *os.File, prefix string, tw *tar.Writer) error {
	// log.Println(file.Name())
	defer file.Close()
	info, err := file.Stat()
	if err != nil {
		log.Printf("File.Stat(): %s\n", err)
		return err
	}
	if info.IsDir() {
		prefix = prefix + "/" + info.Name()
		fileInfos, err := file.Readdir(-1)
		if err != nil {
			log.Printf("compressfile: %s\n", err)
			return err
		}
		for _, fi := range fileInfos {
			f, err := os.Open(file.Name() + "/" + fi.Name())
			if err != nil {
				log.Printf("compressfile: %s\n", err)
				return err
			}
			err = compressfile(f, prefix, tw)
			if err != nil {
				log.Printf("compressfile: %s\n", err)
				return err
			}
		}
		return nil
	} else {
		header, err := tar.FileInfoHeader(info, "")
		header.Name = prefix + "/" + header.Name
		if err != nil {
			log.Printf("compressfile: %s\n", err)
			return err
		}
		err = tw.WriteHeader(header)
		if err != nil {
			log.Printf("compressfile: %s\n", err)
			return err
		}
		_, err = io.Copy(tw, file)
		file.Close()
		if err != nil {
			log.Printf("compressfile: %s\n", err)
			return err
		}
	}
	return nil
}
