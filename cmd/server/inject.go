package main

import (
	"github.com/gin-gonic/gin"
	"github.com/go-kratos/kratos-layout/internal/conf"
	"github.com/go-kratos/kratos-layout/internal/server"
	"github.com/go-kratos/kratos/v2"
	"github.com/go-kratos/kratos/v2/log"
)

// initApp init kratos application.
func initApp(bc *conf.Bootstrap, logger log.Logger) (*kratos.App, func(), error) {
	grpcServer := server.NewGRPCServer(bc.Server)
	httpServer := server.NewHTTPServer(bc.Server, gin.Default())
	app := newApp(logger, grpcServer, httpServer)
	return app, func() {}, nil
}
